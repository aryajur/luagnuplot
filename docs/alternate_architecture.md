# Alternate Architecture: Callback-Based Terminals

This document explores an alternative terminal architecture that was considered but **not implemented**. It's documented here for future reference and to explain the design decisions behind the current buffered command architecture.

## Table of Contents

- [Overview](#overview)
- [The Callback Architecture](#the-callback-architecture)
- [How It Would Work](#how-it-would-work)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)
- [Why Current Architecture is Better](#why-current-architecture-is-better)
- [When to Revisit This Design](#when-to-revisit-this-design)

---

## Overview

The **current luacmd terminal architecture** uses a **command buffering** approach:

1. gnuplot calls terminal functions (move, vector, text, etc.)
2. Terminal stores commands in a C array
3. Lua calls `gnuplot.get_commands()` to retrieve all commands at once
4. Lua processes commands and renders as desired

The **alternate callback architecture** would instead:

1. Lua registers callback functions for terminal operations
2. gnuplot calls terminal functions (move, vector, text, etc.)
3. Terminal immediately calls back into registered Lua functions
4. Lua renders directly as commands arrive

---

## The Callback Architecture

### Conceptual Flow

```
┌──────────────────────────────────────────────────┐
│ 1. Lua registers terminal callbacks              │
│    gnuplot.register_terminal({                   │
│        graphics = function() ... end,            │
│        move = function(x,y) ... end,             │
│        vector = function(x,y) ... end,           │
│        put_text = function(x,y,str) ... end      │
│    })                                            │
└────────────────┬─────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────┐
│ 2. User plots                                    │
│    gnuplot.cmd("set terminal luacallback")      │
│    gnuplot.cmd("plot sin(x)")                   │
└────────────────┬─────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────┐
│ 3. gnuplot core calls terminal functions        │
│    LUACB_graphics() → calls Lua graphics()      │
│    LUACB_move(50,100) → calls Lua move(50,100)  │
│    LUACB_vector(51,105) → calls Lua vector()    │
│    ... (2500 callbacks for a typical plot)      │
└────────────────┬─────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────┐
│ 4. Lua functions render directly                │
│    function move(x, y)                          │
│        current_x, current_y = x, y              │
│        path:MoveToPoint(x, y)                   │
│    end                                           │
│    function vector(x, y)                         │
│        path:AddLineToPoint(x, y)                │
│        current_x, current_y = x, y              │
│    end                                           │
└──────────────────────────────────────────────────┘
```

### Terminal Implementation (C)

```c
/* luacallback.trm - Callback-based terminal */

static lua_State *term_L = NULL;
static int ref_graphics = LUA_NOREF;
static int ref_move = LUA_NOREF;
static int ref_vector = LUA_NOREF;
static int ref_put_text = LUA_NOREF;
static int ref_text = LUA_NOREF;

void LUACB_graphics(void)
{
    if (!term_L || ref_graphics == LUA_NOREF) return;

    lua_rawgeti(term_L, LUA_REGISTRYINDEX, ref_graphics);

    if (lua_pcall(term_L, 0, 0, 0) != 0) {
        fprintf(stderr, "graphics() error: %s\n", lua_tostring(term_L, -1));
        lua_pop(term_L, 1);
    }
}

void LUACB_move(unsigned int x, unsigned int y)
{
    if (!term_L || ref_move == LUA_NOREF) return;

    lua_rawgeti(term_L, LUA_REGISTRYINDEX, ref_move);
    lua_pushinteger(term_L, x);
    lua_pushinteger(term_L, y);

    if (lua_pcall(term_L, 2, 0, 0) != 0) {
        fprintf(stderr, "move() error: %s\n", lua_tostring(term_L, -1));
        lua_pop(term_L, 1);
    }
}

void LUACB_vector(unsigned int x, unsigned int y)
{
    if (!term_L || ref_vector == LUA_NOREF) return;

    lua_rawgeti(term_L, LUA_REGISTRYINDEX, ref_vector);
    lua_pushinteger(term_L, x);
    lua_pushinteger(term_L, y);

    if (lua_pcall(term_L, 2, 0, 0) != 0) {
        fprintf(stderr, "vector() error: %s\n", lua_tostring(term_L, -1));
        lua_pop(term_L, 1);
    }
}

// ... similar for put_text, set_color, linewidth, etc.
```

### Lua Binding

```c
static int lua_register_terminal(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TTABLE);

    term_L = L;

    /* Unref old callbacks if any */
    if (ref_graphics != LUA_NOREF) luaL_unref(L, LUA_REGISTRYINDEX, ref_graphics);
    if (ref_move != LUA_NOREF) luaL_unref(L, LUA_REGISTRYINDEX, ref_move);
    if (ref_vector != LUA_NOREF) luaL_unref(L, LUA_REGISTRYINDEX, ref_vector);

    /* Register new callbacks */
    lua_getfield(L, 1, "graphics");
    if (lua_isfunction(L, -1)) {
        ref_graphics = luaL_ref(L, LUA_REGISTRYINDEX);
    } else {
        lua_pop(L, 1);
    }

    lua_getfield(L, 1, "move");
    if (lua_isfunction(L, -1)) {
        ref_move = luaL_ref(L, LUA_REGISTRYINDEX);
    } else {
        lua_pop(L, 1);
    }

    lua_getfield(L, 1, "vector");
    if (lua_isfunction(L, -1)) {
        ref_vector = luaL_ref(L, LUA_REGISTRYINDEX);
    } else {
        lua_pop(L, 1);
    }

    /* ... register other callbacks ... */

    return 0;
}
```

---

## How It Would Work

### Example: SVG Terminal in Lua

```lua
local gnuplot = require("gnuplot")

-- SVG terminal implemented entirely in Lua
local svg_terminal = {
    file = nil,
    current_x = 0,
    current_y = 0,
    current_color = "#000000",

    graphics = function()
        svg_terminal.file = io.open("output.svg", "w")
        svg_terminal.file:write('<?xml version="1.0" encoding="UTF-8"?>\n')
        svg_terminal.file:write('<svg width="800" height="600" xmlns="http://www.w3.org/2000/svg">\n')
        svg_terminal.file:write('  <rect width="100%" height="100%" fill="white"/>\n')
    end,

    move = function(x, y)
        svg_terminal.current_x = x
        svg_terminal.current_y = y
    end,

    vector = function(x, y)
        svg_terminal.file:write(string.format(
            '  <line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>\n',
            svg_terminal.current_x, svg_terminal.current_y,
            x, y, svg_terminal.current_color))
        svg_terminal.current_x = x
        svg_terminal.current_y = y
    end,

    put_text = function(x, y, str)
        svg_terminal.file:write(string.format(
            '  <text x="%d" y="%d" fill="%s">%s</text>\n',
            x, y, svg_terminal.current_color, str))
    end,

    set_color = function(color)
        local r = bit.rshift(bit.band(color, 0xFF0000), 16)
        local g = bit.rshift(bit.band(color, 0x00FF00), 8)
        local b = bit.band(color, 0x0000FF)
        svg_terminal.current_color = string.format("#%02x%02x%02x", r, g, b)
    end,

    text = function()
        svg_terminal.file:write('</svg>\n')
        svg_terminal.file:close()
    end
}

-- Use it
gnuplot.init()
gnuplot.register_terminal(svg_terminal)
gnuplot.cmd("set terminal luacallback")
gnuplot.cmd("plot sin(x)")
print("SVG saved to output.svg")
```

### Example: Live Rendering

```lua
local wx = require("wx")
local gnuplot = require("gnuplot")

-- Create window and graphics context
local frame = wx.wxFrame(...)
local gc = wx.wxGraphicsContext.Create(...)
local path = gc:CreatePath()

-- Terminal that renders directly to wxGraphicsContext
local live_terminal = {
    graphics = function()
        gc:SetBrush(wx.wxWHITE_BRUSH)
        gc:DrawRectangle(0, 0, 800, 600)
        path = gc:CreatePath()
    end,

    move = function(x, y)
        path:MoveToPoint(x, y)
    end,

    vector = function(x, y)
        path:AddLineToPoint(x, y)
        -- Flush and refresh every 100 vectors for progressive rendering
        if vector_count % 100 == 0 then
            gc:StrokePath(path)
            frame:Refresh()
            wx.wxYield()  -- Process events
        end
    end,

    text = function()
        gc:StrokePath(path)
        frame:Refresh()
    end
}

gnuplot.init()
gnuplot.register_terminal(live_terminal)
gnuplot.cmd("set terminal luacallback")
gnuplot.cmd("plot sin(x)")  -- Watch it render in real-time!
```

---

## Advantages

### 1. Write Terminals Entirely in Lua

No C code needed! Implement custom output formats purely in Lua:
- SVG, JSON, XML, HTML Canvas, etc.
- Custom binary formats
- Database storage
- Network streaming

### 2. Live/Progressive Rendering

Show plot being drawn as gnuplot generates it:
```lua
vector = function(x, y)
    draw_line(current_x, current_y, x, y)
    refresh_display()  -- Update screen immediately
    current_x, current_y = x, y
end
```

### 3. Dynamic Terminal Switching

```lua
-- Quick preview
gnuplot.register_terminal(fast_preview_terminal)
gnuplot.cmd("plot sin(x)")

-- High quality render
gnuplot.register_terminal(high_quality_terminal)
gnuplot.cmd("replot")
```

### 4. Easier Development and Debugging

- No need to rebuild gnuplot
- Lua is more accessible than C
- Can add debug logging easily:
```lua
vector = function(x, y)
    print(string.format("Drawing line to (%d, %d)", x, y))
    -- ... actual drawing
end
```

### 5. No Memory for Command Buffer

Commands processed immediately, not stored. Good for very large plots.

---

## Disadvantages

### 1. **Performance Hit** (Major Issue)

**This is the critical problem.**

For a typical `plot sin(x)` with 500 samples:
- ~2,500 drawing commands generated
- **Callback approach**: 2,500 C→Lua boundary crossings
- **Current approach**: 1 C→Lua call to retrieve all commands

**Performance comparison:**

| Architecture | C→Lua calls | Overhead | Time |
|-------------|-------------|----------|------|
| **Current (buffered)** | 1 call | Minimal | ~1ms |
| **Callback** | 2,500 calls | Stack setup, function lookup × 2500 | ~5-10ms |

Each C→Lua call involves:
- Pushing function from registry onto stack
- Pushing arguments
- `lua_pcall()` overhead
- Error checking
- Stack cleanup

While 10ms is still fast, it's **5-10x slower** for no benefit in most cases.

### 2. Error Handling Complexity

What happens if a callback errors mid-plot?

```lua
vector = function(x, y)
    if math.random() < 0.001 then
        error("Random failure!")  -- Uh oh!
    end
    path:AddLineToPoint(x, y)
end
```

- Plot is partially rendered
- gnuplot is in middle of rendering loop
- State may be corrupted
- Need robust error recovery in C code

### 3. State Management Issues

- Must maintain Lua registry references for callbacks
- Memory leaks if not cleaned up properly
- `lua_State` pointer must be valid during entire plot
- Thread safety concerns if gnuplot ever becomes multi-threaded

### 4. Initialization Order

Users must remember:
```lua
gnuplot.register_terminal(my_term)  -- MUST come first
gnuplot.cmd("set terminal luacallback")  -- Then this
```

Getting this wrong would cause silent failures or crashes.

### 5. Can't Re-render Without Re-plotting

Want to render to multiple formats?

**Callback approach:**
```lua
gnuplot.register_terminal(svg_terminal)
gnuplot.cmd("plot sin(x)")  -- 2500 callbacks

gnuplot.register_terminal(png_terminal)
gnuplot.cmd("replot")  -- Another 2500 callbacks

gnuplot.register_terminal(json_terminal)
gnuplot.cmd("replot")  -- Yet another 2500 callbacks
```

Each format requires re-plotting from scratch!

---

## Why Current Architecture is Better

### Key Insight: Current Design ALREADY Provides the Flexibility

**The buffered command approach lets you do everything the callback approach does, but better:**

```lua
local gnuplot = require("gnuplot")

-- Get commands ONCE
gnuplot.cmd("set terminal luacmd size 800,600")
gnuplot.cmd("plot sin(x)")
local result = gnuplot.get_commands()

-- Render to wxWidgets
render_wx(result.commands)

-- Render SAME data to SVG (no re-plotting!)
render_svg(result.commands, "output.svg")

-- Render SAME data to JSON
render_json(result.commands, "data.json")

-- Render SAME data to HTML Canvas
render_canvas(result.commands, "plot.html")

-- All from ONE plot command, ZERO performance penalty!
```

### Implementation Example: SVG Renderer in Lua

```lua
function render_svg(commands, filename)
    local f = io.open(filename, "w")
    f:write('<?xml version="1.0"?>\n')
    f:write('<svg width="800" height="600">\n')

    local current_x, current_y = 0, 0
    local current_color = "#000000"

    for _, cmd in ipairs(commands) do
        if cmd.type == CMD_MOVE then
            current_x, current_y = cmd.x, cmd.y

        elseif cmd.type == CMD_VECTOR then
            f:write(string.format(
                '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s"/>\n',
                current_x, current_y, cmd.x, cmd.y, current_color))
            current_x, current_y = cmd.x, cmd.y

        elseif cmd.type == CMD_COLOR then
            local r = bit.rshift(bit.band(cmd.color, 0xFF0000), 16)
            local g = bit.rshift(bit.band(cmd.color, 0x00FF00), 8)
            local b = bit.band(cmd.color, 0x0000FF)
            current_color = string.format("#%02x%02x%02x", r, g, b)

        elseif cmd.type == CMD_TEXT then
            f:write(string.format(
                '<text x="%d" y="%d" fill="%s">%s</text>\n',
                cmd.x, cmd.y, current_color, cmd.text))
        end
    end

    f:write('</svg>\n')
    f:close()
end
```

**This is pure Lua, no C code needed, and can render to ANY format!**

### Performance Comparison

| Scenario | Current (Buffered) | Callback | Winner |
|----------|-------------------|----------|--------|
| **Single render** | 1 C→Lua call + Lua processing | 2500 C→Lua calls | **Current** (5-10x faster) |
| **Multiple formats** | 1 C→Lua call + Lua processing × N | Must re-plot × N (2500 calls × N) | **Current** (massively faster) |
| **Re-render** | Free (just Lua) | Must re-plot (2500 calls) | **Current** (infinitely faster) |
| **Memory usage** | Store 2500 commands (~200KB) | No storage | **Callback** (if memory constrained) |
| **Progressive rendering** | Not supported | Supported | **Callback** |

### Flexibility Comparison

| Feature | Current (Buffered) | Callback |
|---------|-------------------|----------|
| **Custom renderers in Lua** | ✅ Yes | ✅ Yes |
| **Multiple formats from one plot** | ✅ Yes (fast) | ❌ Must re-plot |
| **Re-render with different settings** | ✅ Yes (instant) | ❌ Must re-plot |
| **Post-process commands** | ✅ Yes (filter, optimize) | ❌ No |
| **Render in any order** | ✅ Yes | ❌ Must follow gnuplot order |
| **Cache for animation** | ✅ Yes (one plot, many frames) | ❌ Re-plot per frame |
| **Live/progressive rendering** | ❌ No | ✅ Yes |

**Current architecture wins on almost every metric!**

---

## When to Revisit This Design

The callback architecture might become relevant if:

### 1. Memory-Constrained Environments

If storing 2500 commands (~200KB) is too much:
- Embedded systems with very limited RAM
- Plotting millions of data points (commands would be huge)

**Solution**: Implement streaming callback terminal as an **optional addition**.

### 2. Real-Time Progressive Visualization

If users want to see plot being drawn as it's generated:
- Long-running plots (3D, huge datasets)
- Visual feedback during computation

**Solution**: Could implement progressive rendering with current architecture by:
```lua
-- Partial command retrieval
while gnuplot.is_plotting() do
    local partial = gnuplot.get_commands_partial()
    render(partial)
    wx.wxYield()
end
```

### 3. Gnuplot Becomes Async/Multi-threaded

If gnuplot core starts generating plots asynchronously:
- Callbacks might fit better with async architecture
- But would need thread-safe Lua state management

**Unlikely**: Gnuplot has been synchronous for 30+ years.

---

## Conclusion

The **callback-based terminal architecture** was considered and offers some interesting capabilities (live rendering, pure Lua terminals). However, it has a critical flaw: **performance**.

The **current buffered command architecture** is superior because:

1. ✅ **5-10x faster** (1 C→Lua call vs 2500)
2. ✅ **More flexible** (render to multiple formats without re-plotting)
3. ✅ **Simpler error handling** (Lua errors don't corrupt gnuplot state)
4. ✅ **Better for caching/animation** (store commands, re-render cheaply)
5. ✅ **Still allows custom Lua terminals** (process commands in Lua however you want)

The callback approach only wins for:
- Progressive/live rendering (niche use case)
- Extreme memory constraints (rare)

**Recommendation**: Keep current architecture. If streaming/progressive rendering becomes important, implement callback terminal as an **optional addition**, not a replacement.

---

## See Also

- [ADVANCED.md](ADVANCED.md) - Terminal architecture overview
- [API.md](API.md) - Lua API reference
- `examples/wxlua_plot_perfect.lua` - Example of rendering commands in Lua
