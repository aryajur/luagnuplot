# Advanced Topics

This document covers advanced topics including terminal architecture, the RGB feature implementation, wxLua terminal details, and custom terminal development.

## Table of Contents

- [Gnuplot Terminal Architecture](#gnuplot-terminal-architecture)
- [luacmd Terminal Implementation](#luacmd-terminal-implementation)
- [RGB Data Access Feature](#rgb-data-access-feature)
- [Creating Custom Terminals](#creating-custom-terminals)

---

## Gnuplot Terminal Architecture

### Overview

Gnuplot uses a **terminal driver** system where all output formats (SVG, PNG, PostScript, etc.) are implemented as terminals that receive drawing commands from the core plotting engine.

### Data Flow

```
Gnuplot Core (evaluate functions, parse data)
    ↓
Plot Generation (graphics.c, graph3d.c)
    ↓
Terminal Driver Functions
    ↓
Output (SVG, PNG, wxLua commands, etc.)
```

### Terminal Function Interface

All terminals implement a standard API of function pointers:

```c
struct termentry {
    const char *name;              // Terminal name (e.g., "luacmd", "svg")
    const char *description;       // Description

    // Lifecycle
    void (*init)(void);           // Initialize terminal
    void (*reset)(void);          // Reset terminal state
    void (*graphics)(void);       // Enter graphics mode
    void (*text)(void);          // Exit graphics mode, finalize output

    // Drawing primitives
    void (*move)(unsigned int x, unsigned int y);        // Move cursor
    void (*vector)(unsigned int x, unsigned int y);      // Draw line
    void (*put_text)(unsigned int x, unsigned int y, const char *str);  // Draw text
    void (*point)(unsigned int x, unsigned int y, int number);  // Draw point

    // Styling
    void (*linewidth)(double lw);                        // Set line width
    void (*linetype)(int lt);                           // Set line type/style
    void (*set_color)(t_colorspec *colorspec);          // Set drawing color
    void (*fillbox)(int style, unsigned int x1, unsigned int y1,
                    unsigned int width, unsigned int height);  // Fill rectangle
    void (*filled_polygon)(int points, gpiPoint *corners);  // Fill polygon

    // Text formatting
    void (*justify_text)(enum JUSTIFY mode);            // Set text alignment
    void (*text_angle)(int angle);                     // Set text rotation
    void (*set_font)(const char *font);                // Set font

    // Terminal properties
    unsigned int xmax, ymax;      // Canvas dimensions
    unsigned int v_char, h_char;  // Character size
    unsigned int v_tic, h_tic;   // Tic mark size
};
```

### How Terminals Work

When you execute `plot sin(x)`:

1. **Terminal Selection**: `set terminal luacmd size 800,600`
   - Calls `term->init()` to set up the terminal
   - Sets canvas size (`xmax`, `ymax`)

2. **Enter Graphics Mode**: Gnuplot calls `term->graphics()`
   - Terminal prepares for drawing
   - Allocates buffers, clears canvas, etc.

3. **Drawing Commands**: Gnuplot evaluates the plot and calls:
   - `term->linewidth(2.0)` - Set line width
   - `term->set_color(&color)` - Set color
   - `term->move(100, 200)` - Move to starting point
   - `term->vector(150, 250)` - Draw line to next point
   - `term->vector(200, 300)` - Continue line
   - `term->put_text(400, 50, "sin(x)")` - Draw text labels
   - ... hundreds or thousands more commands

4. **Finalize**: `term->text()`
   - Exit graphics mode
   - Write output file, flush buffers, etc.

### How the luacmd Terminal Works

#### Key Concept: Terminals Receive Drawing Primitives, Not Commands

**Important**: When you execute `gnuplot.cmd("plot sin(x)")`, the terminal functions are **NOT** passed the text "plot sin(x)". By the time the terminal is involved, gnuplot has already:

- Parsed all commands
- Performed all mathematical calculations
- Evaluated sin(x) at sample points
- Determined exact pixel positions for every element
- Decided colors, line widths, and text positions

The terminal only receives **low-level drawing primitives** like:
- "Move pen to position (50, 100)"
- "Draw line to position (51, 105)"
- "Set color to RGB(255, 0, 0)"
- "Draw text 'sin(x)' at position (400, 50)"

Think of it like this: Gnuplot is a painter who has already planned the entire painting. The terminal is just the brush that makes the marks on canvas.

#### How luacmd Differs from Normal Terminals

**Normal terminals (like PNG):**
```
1. gnuplot calls drawing functions
2. Terminal directly draws to file/screen
3. Result: PNG file created immediately
```

**luacmd terminal (memory-based):**
```
1. gnuplot calls drawing functions
2. Terminal RECORDS commands instead of drawing
3. Commands stored in memory array
4. Lua calls gnuplot.get_commands() to retrieve them
5. Lua does the actual rendering using any graphics library
```

**Why this design?** Because we're using gnuplot as a library, not a standalone program. We want Lua to control when and how rendering happens, giving us flexibility for GUI integration, animation, custom styling, etc.

#### Complete Data Flow

Here's the complete journey from Lua command to rendered graphics:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Lua script executes:                                    │
│    gnuplot.cmd("plot sin(x)")                              │
└────────────────┬────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. libgnuplot.c: gnuplot_cmd() function                    │
│    - Receives string "plot sin(x)"                         │
│    - Calls gnuplot internal: do_string_and_free()          │
└────────────────┬────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. gnuplot core processes command:                         │
│    - Parses "plot sin(x)" syntax                           │
│    - Evaluates sin(x) at 500 sample points                 │
│    - Calculates axis positions, labels, grid lines         │
│    - Prepares all rendering coordinates                    │
└────────────────┬────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. gnuplot calls luacmd terminal functions:                 │
│    LUACMD_graphics()    ← "Start rendering"                 │
│    LUACMD_move(50, 100) ← "Move pen to (50,100)"            │
│    LUACMD_vector(51,105)← "Draw line to (51,105)"           │
│    LUACMD_set_color(RED)← "Change color to red"             │
│    LUACMD_put_text(...)← "Draw text label"                  │
│    LUACMD_text()        ← "Done rendering"                  │
└────────────────┬────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Each luacmd terminal function calls back to libgnuplot: │
│    luacmd_add_command(CMD_MOVE, 50, 100, ...)               │
│    luacmd_add_command(CMD_VECTOR, 51, 105, ...)             │
│    luacmd_add_command(CMD_COLOR, 0xFF0000, ...)             │
└────────────────┬────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. libgnuplot.c stores commands in array:                  │
│    commands[0] = {type: CMD_MOVE, x: 50, y: 100}           │
│    commands[1] = {type: CMD_VECTOR, x: 51, y: 105}         │
│    commands[2] = {type: CMD_COLOR, color: 0xFF0000}        │
│    ... (thousands of commands for a typical plot)          │
└────────────────┬────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Lua script retrieves commands:                          │
│    local result = gnuplot.get_commands()                   │
└────────────────┬────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. libgnuplot.c returns data to Lua:                       │
│    {width=800, height=600, commands={...2500 items...}}    │
└────────────────┬────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ 9. Lua renders using wxWidgets:                            │
│    - Create wxBitmap and wxGraphicsContext                 │
│    - Loop through commands                                 │
│    - For each CMD_MOVE: path:MoveToPoint()                 │
│    - For each CMD_VECTOR: path:AddLineToPoint()            │
│    - For each CMD_TEXT: memDC:DrawText()                   │
│    - Display in wxStaticBitmap or save as PNG              │
└─────────────────────────────────────────────────────────────┘
```

#### Example: What the Terminal Actually Sees

When you run:
```lua
gnuplot.cmd("plot sin(x)")
```

The terminal does **NOT** see "plot sin(x)". Instead, it receives approximately 2,500 function calls like:

```c
LUACMD_graphics()
LUACMD_linewidth(1.0)
LUACMD_set_color(BLACK)
LUACMD_move(100, 300)      // Start of axis
LUACMD_vector(700, 300)    // Draw X axis
LUACMD_move(100, 100)      // Start of Y axis
LUACMD_vector(100, 500)    // Draw Y axis
LUACMD_set_color(BLUE)     // First plot line
LUACMD_linewidth(2.0)
LUACMD_move(100, 300)      // sin(x) starts
LUACMD_vector(101, 305)    // sin(x) point 2
LUACMD_vector(102, 310)    // sin(x) point 3
// ... 497 more vectors for the curve
LUACMD_put_text(400, 50, "sin(x)")  // Label
LUACMD_text()
```

The terminal has no knowledge of mathematics, functions, or commands. It's purely a drawing interface.

### Terminal Types

**File-based terminals** (svg, png, pdf):
- Write directly to files during rendering
- `text()` function closes the file

**Memory-based terminals** (luacmd):
- Store drawing commands in memory
- Application retrieves commands after plotting
- Allows custom rendering

---

## luacmd Terminal Implementation

The luacmd terminal is a custom terminal that captures gnuplot's drawing commands for rendering with any Lua graphics library.

### Architecture

```
Gnuplot plot command
    ↓
luacmd terminal driver (term/luacmd.trm)
    ↓
Command queue (stored in libgnuplot.c)
    ↓
Lua retrieves via gnuplot.get_commands()
    ↓
Rendering with any Lua library (wxWidgets, Cairo, SVG, JSON, etc.)
```

### Implementation Details

**Location**: `gnuplot-source/term/luacmd.trm`

**Key Features**:
1. **Command Capture**: Instead of rendering directly, stores commands in a queue
2. **Memory Management**: Commands stored in global buffer accessible from Lua
3. **Canvas Size**: Configurable via `set terminal luacmd size WIDTH,HEIGHT`
4. **Flexible Rendering**: Commands can be rendered with any Lua graphics library

**Command Structure**:
```c
typedef struct {
    int type;           // Command type (MOVE, VECTOR, TEXT, etc.)
    double x, y;        // Coordinates
    char *text;         // For TEXT commands
    int color;          // For COLOR commands (0xRRGGBB)
    double value;       // For LINEWIDTH, TEXT_ANGLE
} luacmd_command;
```

**Command Types**:
```c
#define CMD_MOVE            0
#define CMD_VECTOR          1
#define CMD_TEXT            2
#define CMD_COLOR           3
#define CMD_LINEWIDTH       4
#define CMD_LINETYPE        5
#define CMD_POINT           6
#define CMD_FILLBOX         7
#define CMD_FILLED_POLYGON  8
#define CMD_TEXT_ANGLE      9
#define CMD_JUSTIFY         10
#define CMD_SET_FONT        11
```

### Rendering Optimizations

The `wxlua_plot_perfect.lua` example demonstrates several rendering optimizations when using wxLua/wxWidgets:

**1. Path Accumulation**
Instead of drawing individual line segments, accumulate consecutive vectors into paths:

```lua
local path_points = {}

-- Accumulate points
if cmd.type == CMD_MOVE then
    path_points = {{x = cmd.x, y = cmd.y}}
elseif cmd.type == CMD_VECTOR then
    table.insert(path_points, {x = cmd.x, y = cmd.y})
end

-- Flush when path ends (color change, line style change, etc.)
function flush_path()
    local path = gc:CreatePath()
    path:MoveToPoint(path_points[1].x, path_points[1].y)
    for i = 2, #path_points do
        path:AddLineToPoint(path_points[i].x, path_points[i].y)
    end
    gc:StrokePath(path)
end
```

**2. wxGraphicsContext for Anti-aliasing**
```lua
local gc = wx.wxGraphicsContext.Create(memDC)
gc:SetAntialiasMode(wx.wxANTIALIAS_DEFAULT)
gc:SetInterpolationQuality(wx.wxINTERPOLATION_BEST)
```

**3. Round Caps and Joins**
```lua
local pen = wx.wxPen(color, width, style)
pen:SetCap(wx.wxCAP_ROUND)
pen:SetJoin(wx.wxJOIN_ROUND)
```

**4. Alpha Blending for Smooth Curves**
```lua
-- Detect plot curves vs grid/borders
local is_curve = (#path_points > 20)

if is_curve and pen_width >= 2 then
    actual_width = pen_width * 1.15  -- Slightly wider
    alpha = 225  -- Subtle transparency
end

local pen = wx.wxPen(wx.wxColour(r, g, b, alpha), actual_width, style)
```

### Typical Plot Statistics

For `plot sin(x), cos(x)` with 500 samples:
- Canvas size: 1000x700 pixels
- Total commands: ~2500
- Path segments: ~2000 (vectors)
- Text labels: ~50
- When rendered with path accumulation: ~45 paths

---

## RGB Data Access Feature

### Overview

The RGB feature allows direct access to plot bitmap data without file I/O, perfect for GUI integration and real-time visualization.

### Architecture

1. **Terminal Integration**: Modified PBM color terminal saves bitmap data before freeing it
2. **Global Buffer**: RGB data stored in persistent buffer in `libgnuplot.c`
3. **Lua Access**: `gnuplot.get_rgb_data()` retrieves the saved data

### Implementation

**Location**: `gnuplot-source/term/pbm.trm`

**Modified PBM Terminal**:
```c
TERM_PUBLIC void PBM_text()
{
    if (pbm_mode == PBM_COLOR && b_p != NULL) {
        // Save RGB data before freeing bitmap
        save_rgb_data(b_p, b_psize, pbm_xmax, pbm_ymax);
    }

    // Original cleanup code
    if (b_p != NULL) {
        free(b_p);
        b_p = NULL;
    }
}
```

**Storage in libgnuplot.c**:
```c
typedef struct {
    unsigned char *data;  // RGB bytes
    int width;
    int height;
    int valid;            // Data available flag
} rgb_data_t;

static rgb_data_t saved_rgb_data = {NULL, 0, 0, 0};

void save_rgb_data(unsigned char *data, size_t size, int width, int height)
{
    // Free previous data
    if (saved_rgb_data.data != NULL) {
        free(saved_rgb_data.data);
    }

    // Allocate and copy
    saved_rgb_data.data = malloc(size);
    memcpy(saved_rgb_data.data, data, size);
    saved_rgb_data.width = width;
    saved_rgb_data.height = height;
    saved_rgb_data.valid = 1;
}
```

**Lua Binding** (in `lua_gnuplot.c`):
```c
static int lua_get_rgb_data(lua_State *L)
{
    const rgb_data_t *data = get_rgb_data();

    if (data == NULL || !data->valid) {
        lua_pushnil(L);
        lua_pushstring(L, "No RGB data available");
        return 2;
    }

    lua_newtable(L);
    lua_pushinteger(L, data->width);
    lua_setfield(L, -2, "width");
    lua_pushinteger(L, data->height);
    lua_setfield(L, -2, "height");
    lua_pushlstring(L, (const char *)data->data,
                    data->width * data->height * 3);
    lua_setfield(L, -2, "data");

    return 1;
}
```

### RGB Data Format

- **Byte order**: R, G, B, R, G, B, R, G, B, ...
- **Pixel order**: Left-to-right, top-to-bottom
- **Size**: `width * height * 3` bytes
- **Value range**: 0-255 per channel

### Usage Example

```lua
gnuplot.init()
gnuplot.cmd("set terminal pbm color size 800,600")
gnuplot.cmd("set output '/dev/null'")
gnuplot.cmd("plot sin(x)")

local rgb, err = gnuplot.get_rgb_data()
if rgb then
    -- Create wxImage from RGB data
    local image = wx.wxImage(rgb.width, rgb.height)
    image:SetData(rgb.data)

    -- Convert to bitmap
    local bitmap = wx.wxBitmap(image)

    -- Display in wxStaticBitmap
    local staticBitmap = wx.wxStaticBitmap(panel, wx.wxID_ANY, bitmap)
end

gnuplot.close()
```

---

## Creating Custom Terminals

You can create custom terminals to output gnuplot data in any format.

### Step 1: Create Terminal Source File

Create `gnuplot-source/term/myterm.trm`:

```c
/* My custom terminal */

#ifndef TERM_PROTO_ONLY
#ifdef TERM_BODY

#define MYTERM_XMAX 800
#define MYTERM_YMAX 600

TERM_PUBLIC void MYTERM_init()
{
    // Initialize terminal
    fprintf(stderr, "MyTerm initialized\n");
}

TERM_PUBLIC void MYTERM_graphics()
{
    // Enter graphics mode
    printf("BEGIN_PLOT %d %d\n", MYTERM_XMAX, MYTERM_YMAX);
}

TERM_PUBLIC void MYTERM_move(unsigned int x, unsigned int y)
{
    printf("MOVE %u %u\n", x, y);
}

TERM_PUBLIC void MYTERM_vector(unsigned int x, unsigned int y)
{
    printf("LINE %u %u\n", x, y);
}

TERM_PUBLIC void MYTERM_put_text(unsigned int x, unsigned int y, const char *str)
{
    printf("TEXT %u %u \"%s\"\n", x, y, str);
}

TERM_PUBLIC void MYTERM_text()
{
    // Finalize
    printf("END_PLOT\n");
}

TERM_PUBLIC void MYTERM_reset()
{
    // Reset terminal
}

#endif /* TERM_BODY */

#ifdef TERM_TABLE
TERM_TABLE_START(myterm_driver)
    "myterm",                     // Terminal name
    "My custom terminal",         // Description
    MYTERM_XMAX, MYTERM_YMAX,    // Canvas size
    12, 7,                        // Character size (v_char, h_char)
    10, 10,                       // Tic size (v_tic, h_tic)
    MYTERM_init,
    MYTERM_reset,
    MYTERM_graphics,
    MYTERM_text,
    MYTERM_move,
    MYTERM_vector,
    MYTERM_put_text,
    // ... other function pointers
TERM_TABLE_END(myterm_driver)

#undef LAST_TERM
#define LAST_TERM myterm_driver
#endif /* TERM_TABLE */
#endif /* TERM_PROTO_ONLY */
```

### Step 2: Register Terminal

Edit `gnuplot-source/term.h` and add:

```c
#include "term/myterm.trm"
```

### Step 3: Rebuild

```bash
make clean
./build.sh
```

### Step 4: Use Custom Terminal

```lua
gnuplot.init()
gnuplot.cmd("set terminal myterm")
gnuplot.cmd("plot sin(x)")
gnuplot.close()
```

Output:
```
BEGIN_PLOT 800 600
MOVE 100 300
LINE 110 295
LINE 120 285
TEXT 400 50 "sin(x)"
END_PLOT
```

### Advanced: Memory-Based Terminal with Lua Access

To create a terminal like luacmd that stores data for Lua retrieval:

1. **Store commands in global buffer** (libgnuplot.c)
2. **Add Lua binding** (lua_gnuplot.c)
3. **Implement getter function** similar to `get_commands()`

See the wxlua terminal implementation in `term/luacmd.trm` for a complete example.

---

## Performance Considerations

### luacmd Terminal Performance

**Typical plot with 500 samples:**
- Command generation: <10ms
- Command transfer to Lua: <1ms
- wxWidgets rendering: 50-100ms
- Total: ~100ms

**Optimization tips:**
1. Use path accumulation (45 paths vs 2000 individual lines)
2. Pre-render to bitmap, display bitmap (not live rendering)
3. Use wxGraphicsContext for smooth anti-aliasing
4. 32-bit bitmap depth for alpha channel support

### RGB Feature Performance

**800x600 plot:**
- RGB data size: 1.44 MB (800 * 600 * 3)
- Memory copy overhead: <5ms
- Transfer to Lua: <10ms
- wxImage creation: <20ms
- Total: ~35ms

**Much faster than:**
- PNG file write + read: ~200ms
- SVG write + parse + render: ~300ms

---

## See Also

- [API Reference](API.md) - Complete Lua module API
- [wxlua_plot_perfect.lua](../wxlua_plot_perfect.lua) - Optimized wxLua rendering example
- [Gnuplot Documentation](http://www.gnuplot.info/documentation.html) - Official gnuplot docs
