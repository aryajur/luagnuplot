# Gnuplot Lua Module - API Reference

Complete API documentation for the `gnuplot` and `wxgnuplot` Lua modules.

## Table of Contents

- [Module Loading](#module-loading)
- [gnuplot Module](#gnuplot-module)
  - [Core Functions](#core-functions)
  - [Command Execution](#command-execution)
  - [Convenience Wrappers](#convenience-wrappers)
  - [Data Handling](#data-handling)
  - [Terminal-Specific Functions](#terminal-specific-functions)
- [wxgnuplot Module](#wxgnuplot-module)
  - [Module Overview](#module-overview)
  - [Wrapped Functions](#wrapped-functions)
  - [Convenience Functions](#convenience-functions)
  - [Plot Widget](#plot-widget)
- [Complete Examples](#complete-examples)
- [Error Handling](#error-handling)

## Module Loading

### gnuplot Module (Low-level C bindings)

```lua
local gnuplot = require("gnuplot")
```

**Requirements:**
- `gnuplot.so` (Linux) or `gnuplot.dll` (Windows) must be in your `LUA_CPATH`
- `libgnuplot.so` (Linux) or `libgnuplot.dll` (Windows) must be in your library path

**Environment Setup:**
```bash
# Linux
export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
export LUA_CPATH='./?.so;;'

# Windows
set PATH=.;%PATH%
set LUA_CPATH=./?.dll;;
```

### wxgnuplot Module (Recommended high-level interface)

```lua
local wxgnuplot = require("wxgnuplot")
```

**Requirements:**
- Same as gnuplot module (wxgnuplot wraps gnuplot internally)
- For plot widgets: wxLua library

**Note:** `wxgnuplot` is the recommended interface for Lua programs. It wraps the `gnuplot` module and provides additional convenience functions and plot widgets.

---

## gnuplot Module

The low-level C binding module providing direct access to gnuplot functionality.

### Core Functions

#### gnuplot.init()

Initialize the gnuplot library. Must be called before any other gnuplot operations.

**Syntax:**
```lua
success = gnuplot.init()
```

**Returns:**
- `true` if initialization succeeded
- `false` if initialization failed

**Example:**
```lua
local gnuplot = require("gnuplot")
if gnuplot.init() then
    print("Gnuplot initialized successfully")
else
    print("Gnuplot initialization failed")
end
```

**Notes:**
- Only needs to be called once per session
- Automatically initializes with 'dumb' terminal if GNUTERM not set
- Safe to call multiple times (subsequent calls are no-ops)

---

#### gnuplot.is_initialized()

Check if the gnuplot library has been initialized.

**Syntax:**
```lua
initialized = gnuplot.is_initialized()
```

**Returns:**
- `true` if gnuplot is initialized
- `false` if not initialized

**Example:**
```lua
if not gnuplot.is_initialized() then
    gnuplot.init()
end
```

---

#### gnuplot.version()

Get the gnuplot version string.

**Syntax:**
```lua
version_string = gnuplot.version()
```

**Returns:**
- String containing gnuplot version and patchlevel

**Example:**
```lua
gnuplot.init()
print("Gnuplot version: " .. gnuplot.version())
-- Output: "Gnuplot version: 6.1 patchlevel 0"
```

---

#### gnuplot.reset()

Reset gnuplot to its initial state, clearing all settings and plots.

**Syntax:**
```lua
gnuplot.reset()
```

**Returns:** `nil`

**Example:**
```lua
gnuplot.cmd("set title 'Test'")
gnuplot.cmd("plot sin(x)")
gnuplot.reset()  -- Clears title, plot, and all other settings
```

**Notes:**
- Equivalent to calling `gnuplot.cmd("reset")`
- Keeps gnuplot initialized (doesn't require re-init)

---

#### gnuplot.close()

Clean up and close the gnuplot library. Should be called when done with plotting.

**Syntax:**
```lua
gnuplot.close()
```

**Returns:** `nil`

**Example:**
```lua
gnuplot.init()
gnuplot.cmd("set terminal svg")
gnuplot.cmd("set output 'plot.svg'")
gnuplot.cmd("plot sin(x)")
gnuplot.close()  -- Clean up resources
```

**Notes:**
- Resets terminal and clears initialization state
- After calling close(), must call init() again to use gnuplot

---

### Command Execution

#### gnuplot.cmd(command)

Execute a single gnuplot command.

**Syntax:**
```lua
success = gnuplot.cmd(command)
```

**Parameters:**
- `command` (string) - A gnuplot command string

**Returns:**
- `true` if command executed successfully
- `false` if command failed

**Examples:**
```lua
-- Set terminal
gnuplot.cmd("set terminal svg size 800,600")

-- Set output file
gnuplot.cmd("set output 'plot.svg'")

-- Configure plot appearance
gnuplot.cmd("set title 'My Plot'")
gnuplot.cmd("set xlabel 'X axis'")
gnuplot.cmd("set ylabel 'Y axis'")
gnuplot.cmd("set grid")

-- Create plot
gnuplot.cmd("plot sin(x)")
```

**Common Commands:**

**Terminal selection:**
```lua
gnuplot.cmd("set terminal svg size 800,600")
gnuplot.cmd("set terminal png size 1024,768")
gnuplot.cmd("set terminal pbm color size 640,480")
gnuplot.cmd("set terminal luacmd size 1000,700")
```

**Output file:**
```lua
gnuplot.cmd("set output 'filename.svg'")
gnuplot.cmd("set output '/dev/null'")  -- No file output
gnuplot.cmd("set output")  -- Close output file
```

**Plot styling:**
```lua
gnuplot.cmd("set title 'Plot Title'")
gnuplot.cmd("set xlabel 'X Label'")
gnuplot.cmd("set ylabel 'Y Label'")
gnuplot.cmd("set grid")
gnuplot.cmd("set key top right")  -- Legend position
gnuplot.cmd("set xrange [-10:10]")
gnuplot.cmd("set yrange [-5:5]")
```

**Plotting:**
```lua
gnuplot.cmd("plot sin(x)")
gnuplot.cmd("plot sin(x), cos(x), tan(x)")
gnuplot.cmd("plot sin(x) title 'Sine' with lines lw 2")
gnuplot.cmd("splot x*y")  -- 3D plot
```

**Special Behavior:**
- Automatically hooks terminal for `plot`, `splot`, and `replot` commands
- This enables automatic bitmap saving for `get_pbm_rgb_data()`

---

#### gnuplot.cmd_multi(commands)

Execute multiple newline-separated gnuplot commands.

**Syntax:**
```lua
success = gnuplot.cmd_multi(commands)
```

**Parameters:**
- `commands` (string) - Multiple gnuplot commands separated by newlines

**Returns:**
- `true` if all commands executed successfully
- `false` if any command failed (stops at first error)

**Example:**
```lua
local cmds = [[
set terminal svg size 800,600
set output 'plot.svg'
set title 'Multiple Commands'
set grid
plot sin(x), cos(x)
]]

gnuplot.cmd_multi(cmds)
```

**Features:**
- Automatically skips empty lines
- Skips comment lines (starting with `#`)
- Stops execution on first error
- Cross-platform newline handling

**Notes:**
- Can be implemented in Lua using `cmd()` in a loop
- Provided in C for convenience and slight performance benefit
- For data blocks, prefer `set_datablock()` instead

---

### Convenience Wrappers

These functions are simple wrappers around `cmd()` provided for convenience. They're also available (and recommended) in the `wxgnuplot` module.

#### gnuplot.plot(expression, options)

Wrapper for the "plot" command.

**Syntax:**
```lua
success = gnuplot.plot(expression, options)
```

**Parameters:**
- `expression` (string) - Plot expression or data source
- `options` (string, optional) - Additional plot options

**Returns:**
- `true` if command executed successfully
- `false` if command failed

**Example:**
```lua
gnuplot.plot("sin(x)")
gnuplot.plot("sin(x)", "title 'Sine' with lines lw 2")
```

**Equivalent to:**
```lua
gnuplot.cmd("plot " .. expression .. " " .. (options or ""))
```

---

#### gnuplot.splot(expression, options)

Wrapper for the "splot" (3D plot) command.

**Syntax:**
```lua
success = gnuplot.splot(expression, options)
```

**Parameters:**
- `expression` (string) - 3D plot expression or data source
- `options` (string, optional) - Additional plot options

**Returns:**
- `true` if command executed successfully
- `false` if command failed

**Example:**
```lua
gnuplot.splot("x*y")
gnuplot.splot("x**2 + y**2", "with pm3d")
```

---

#### gnuplot.set(option)

Wrapper for the "set" command.

**Syntax:**
```lua
success = gnuplot.set(option)
```

**Parameters:**
- `option` (string) - gnuplot set option

**Returns:**
- `true` if command executed successfully
- `false` if command failed

**Example:**
```lua
gnuplot.set("grid")
gnuplot.set("title 'My Plot'")
gnuplot.set("terminal svg size 800,600")
```

**Equivalent to:**
```lua
gnuplot.cmd("set " .. option)
```

---

#### gnuplot.unset(option)

Wrapper for the "unset" command.

**Syntax:**
```lua
success = gnuplot.unset(option)
```

**Parameters:**
- `option` (string) - gnuplot option to unset

**Returns:**
- `true` if command executed successfully
- `false` if command failed

**Example:**
```lua
gnuplot.unset("grid")
gnuplot.unset("key")  -- Remove legend
```

---

### Data Handling

#### gnuplot.set_datablock(name, data)

Set datablock content directly, bypassing heredoc syntax.

**Syntax:**
```lua
success = gnuplot.set_datablock(name, data)
```

**Parameters:**
- `name` (string) - Datablock name (with or without `$` prefix)
- `data` (string) - Newline-separated data lines

**Returns:**
- `true` if datablock was set successfully
- `false` if operation failed

**Example:**
```lua
-- Simple data
gnuplot.set_datablock("$DATA", "1 2\n2 4\n3 6\n4 8")
gnuplot.cmd("plot $DATA with lines")

-- Data from Lua table
local points = {}
for i = 1, 100 do
    local x = i / 10
    local y = math.sin(x)
    table.insert(points, string.format("%f %f", x, y))
end

gnuplot.set_datablock("MYDATA", table.concat(points, "\n"))
gnuplot.cmd("plot $MYDATA with lines title 'sin(x)'")
```

**Advantages over heredoc:**
- No heredoc syntax issues
- Works reliably across all platforms
- Cleaner Lua code
- Direct API call to gnuplot internals

**Notes:**
- Automatically adds `$` prefix if not provided
- Replaces existing datablock if name already exists
- More efficient than writing to temporary files

---

### Terminal-Specific Functions

#### gnuplot.get_pbm_rgb_data()

Get raw RGB pixel data from the PBM terminal. **Only works with PBM terminal.**

**Syntax:**
```lua
rgb_data, error = gnuplot.get_pbm_rgb_data()
```

**Returns:**
- On success: table with RGB data
  ```lua
  {
    width = number,       -- Image width in pixels
    height = number,      -- Image height in pixels
    data = string         -- Raw RGB bytes (width * height * 3 bytes)
  }
  ```
- On error: `nil, error_message`

**Requirements:**
1. Must use PBM color terminal: `set terminal pbm color size W,H`
2. Must plot something (triggers automatic bitmap saving)
3. PNG/GIF/JPEG terminals are NOT supported (use file output for those)

**RGB Data Format:**
- Byte sequence: `R1 G1 B1 R2 G2 B2 R3 G3 B3 ...`
- Each pixel is 3 bytes (R, G, B), values 0-255
- Pixels ordered left-to-right, top-to-bottom
- Total size: `width * height * 3` bytes

**Example:**
```lua
gnuplot.init()

-- Use PBM color terminal
gnuplot.cmd("set terminal pbm color size 800,600")
gnuplot.cmd("set output '/dev/null'")  -- Don't write to file
gnuplot.cmd("plot sin(x)")

-- Get RGB data (automatically saved during plot)
local rgb_data, err = gnuplot.get_pbm_rgb_data()

if rgb_data then
    print("Image size:", rgb_data.width, "x", rgb_data.height)
    print("Data bytes:", #rgb_data.data)

    -- Access pixel data
    local data = rgb_data.data
    local pixel1_r = string.byte(data, 1)
    local pixel1_g = string.byte(data, 2)
    local pixel1_b = string.byte(data, 3)

    print("First pixel RGB:", pixel1_r, pixel1_g, pixel1_b)
else
    print("Error:", err)
end

gnuplot.close()
```

**wxLua Integration Example:**
```lua
local wx = require("wx")

-- ... create wxFrame and wxStaticBitmap control ...

-- Plot with PBM terminal
gnuplot.cmd("set terminal pbm color size 640,480")
gnuplot.cmd("set output '/dev/null'")
gnuplot.cmd("plot sin(x)")

-- Get RGB data
local rgb_data = gnuplot.get_pbm_rgb_data()

if rgb_data then
    -- Convert to wxImage
    local image = wx.wxImage(rgb_data.width, rgb_data.height)
    image:SetData(rgb_data.data)

    -- Display in wxStaticBitmap
    local bitmap = wx.wxBitmap(image)
    bitmapCtrl:SetBitmap(bitmap)
end
```

**Use Cases:**
- Direct GUI rendering (wxWidgets, Qt, GTK, etc.)
- Network streaming of plot images
- Custom image processing
- Real-time visualization
- Avoiding file I/O overhead

**Why PBM-only:**
- PBM uses gnuplot's built-in bitmap.c functions
- PNG/GIF/JPEG use libgd with different internal structure
- For PNG/GIF/JPEG, write to file instead (smaller, better quality)

---

#### gnuplot.get_commands()

Retrieve drawing commands generated by the luacmd terminal.

**Syntax:**
```lua
result = gnuplot.get_commands()
```

**Returns:**
- Table with the following structure:
  ```lua
  {
    width = number,      -- Canvas width in pixels
    height = number,     -- Canvas height in pixels
    commands = {         -- Array of command tables
      {type = CMD_MOVE, x = number, y = number},
      {type = CMD_VECTOR, x = number, y = number},
      {type = CMD_TEXT, x = number, y = number, text = string},
      {type = CMD_COLOR, color = number},  -- RGB as 0xRRGGBB
      {type = CMD_LINEWIDTH, value = number},
      {type = CMD_LINETYPE, x = number},
      -- ... more commands
    }
  }
  ```
- Or `nil, error_message` if no commands were captured

**Requirements:**
- Must use luacmd terminal: `set terminal luacmd size W,H`
- Must plot something before calling

**Command Types:**
```lua
local CMD_MOVE = 0            -- Move to position (x, y)
local CMD_VECTOR = 1          -- Draw line to (x, y)
local CMD_TEXT = 2            -- Draw text at (x, y)
local CMD_COLOR = 3           -- Set drawing color
local CMD_LINEWIDTH = 4       -- Set line width
local CMD_LINETYPE = 5        -- Set line style
local CMD_POINT = 6           -- Draw point at (x, y)
local CMD_FILLBOX = 7         -- Draw filled box
local CMD_FILLED_POLYGON = 8  -- Draw filled polygon
local CMD_TEXT_ANGLE = 9      -- Set text rotation angle
local CMD_JUSTIFY = 10        -- Set text justification
local CMD_SET_FONT = 11       -- Set font
```

**Example:**
```lua
gnuplot.init()
gnuplot.cmd("set terminal luacmd size 800,600")
gnuplot.cmd("plot sin(x)")

local result = gnuplot.get_commands()

if result then
    print("Canvas size:", result.width, "x", result.height)
    print("Number of commands:", #result.commands)

    -- Process commands
    for i, cmd in ipairs(result.commands) do
        if cmd.type == 0 then  -- CMD_MOVE
            print("Move to", cmd.x, cmd.y)
        elseif cmd.type == 1 then  -- CMD_VECTOR
            print("Draw line to", cmd.x, cmd.y)
        elseif cmd.type == 2 then  -- CMD_TEXT
            print("Draw text:", cmd.text, "at", cmd.x, cmd.y)
        end
    end
end

gnuplot.close()
```

**Use Cases:**
- Custom rendering in GUI applications
- wxLua plot widgets (see wxgnuplot.new())
- Interactive plot manipulation
- Export to custom formats
- Plot animation

---

## wxgnuplot Module

The high-level wrapper module that provides convenient access to gnuplot functionality and plot widgets for wxLua.

### Module Overview

The `wxgnuplot` module wraps the low-level `gnuplot` module and provides:
1. All gnuplot functions as passthrough wrappers
2. Additional convenience functions
3. Plot widget for wxLua applications

**Loading:**
```lua
local wxgnuplot = require("wxgnuplot")
```

**Note:** This is the recommended module to use in Lua programs. It provides everything from the gnuplot module plus additional features.

### Wrapped Functions

All gnuplot module functions are available through wxgnuplot:

```lua
wxgnuplot.init()                  -- Same as gnuplot.init()
wxgnuplot.cmd(command)            -- Same as gnuplot.cmd()
wxgnuplot.cmd_multi(commands)     -- Same as gnuplot.cmd_multi()
wxgnuplot.reset()                 -- Same as gnuplot.reset()
wxgnuplot.close()                 -- Same as gnuplot.close()
wxgnuplot.version()               -- Same as gnuplot.version()
wxgnuplot.is_initialized()        -- Same as gnuplot.is_initialized()
wxgnuplot.set_datablock(name, data)  -- Same as gnuplot.set_datablock()
wxgnuplot.get_pbm_rgb_data()      -- Same as gnuplot.get_pbm_rgb_data()
wxgnuplot.get_commands()          -- Same as gnuplot.get_commands()
```

### Convenience Functions

#### wxgnuplot.plot(expression, options)

Wrapper for the "plot" command.

**Syntax:**
```lua
success = wxgnuplot.plot(expression, options)
```

**Example:**
```lua
wxgnuplot.init()
wxgnuplot.set("terminal svg size 800,600")
wxgnuplot.set("output 'plot.svg'")
wxgnuplot.plot("sin(x)", "title 'Sine' with lines lw 2")
```

---

#### wxgnuplot.splot(expression, options)

Wrapper for the "splot" command.

**Syntax:**
```lua
success = wxgnuplot.splot(expression, options)
```

---

#### wxgnuplot.set(option)

Wrapper for the "set" command.

**Syntax:**
```lua
success = wxgnuplot.set(option)
```

**Example:**
```lua
wxgnuplot.set("grid")
wxgnuplot.set("title 'My Plot'")
```

---

#### wxgnuplot.unset(option)

Wrapper for the "unset" command.

**Syntax:**
```lua
success = wxgnuplot.unset(option)
```

---

#### wxgnuplot.plot_to_file(output_file, terminal, size, plot_commands)

High-level helper to generate plot files with automatic initialization and cleanup.

**Syntax:**
```lua
filename = wxgnuplot.plot_to_file(output_file, terminal, size, plot_commands)
```

**Parameters:**
- `output_file` (string) - Output filename
- `terminal` (string) - Terminal type and options (e.g., "png", "svg", "pbm color")
- `size` (string) - Size specification (e.g., "800x600", "800,600", "1024x768")
- `plot_commands` (string or table) - Plot commands to execute

**Returns:**
- Output filename on success

**Examples:**

**String commands:**
```lua
wxgnuplot.plot_to_file("output.png", "png", "800x600",
    "set title 'Test'\nset grid\nplot sin(x)")
```

**Table of commands:**
```lua
local cmds = {
    "set title 'Trigonometric Functions'",
    "set xlabel 'X axis'",
    "set ylabel 'Y axis'",
    "set grid",
    "plot sin(x) title 'sin(x)' with lines lw 2, cos(x) title 'cos(x)' with lines lw 2"
}

wxgnuplot.plot_to_file("trig.svg", "svg", "1024,768", cmds)
```

**Features:**
- Automatically calls `init()` if not initialized
- Parses size flexibly ("800x600", "800,600", or "800 600")
- Automatically closes output file
- Returns filename for chaining

**Use Cases:**
- Quick plot generation
- Batch processing
- Scripting multiple plots
- Simple file output without manual terminal setup

---

### Plot Widget

#### wxgnuplot.new(parent, id, pos, size)

Create a wxLua plot widget that can render gnuplot commands in real-time.

**Syntax:**
```lua
plot = wxgnuplot.new(parent, id, pos, size)
```

**Parameters:**
- `parent` (wxWindow) - Parent window
- `id` (number, optional) - Window ID (default: wx.wxID_ANY)
- `pos` (wxPoint, optional) - Position (default: wx.wxDefaultPosition)
- `size` (wxSize, optional) - Size (default: wx.wxSize(400, 300))

**Returns:**
- Plot widget object

**Plot Widget Methods:**

##### plot:getPanel()

Get the underlying wxPanel for adding to sizers.

**Returns:** wxPanel

**Example:**
```lua
local plot = wxgnuplot.new(frame, wx.wxID_ANY)
sizer:Add(plot:getPanel(), 1, wx.wxEXPAND)
```

---

##### plot:cmd(command)

Add a gnuplot command to the command stack.

**Parameters:**
- `command` (string) - Gnuplot command

**Example:**
```lua
plot:cmd("set title 'My Plot'")
plot:cmd("set grid")
```

**Notes:**
- Commands are accumulated, not executed immediately
- Call `execute()` to render the plot

---

##### plot:cmd_multi(commands)

Add multi-line command block (for data blocks with heredoc syntax).

**Parameters:**
- `commands` (string) - Multi-line commands including heredoc data

**Example:**
```lua
plot:cmd_multi([[
$DATA << EOD
1 2
2 4
3 6
4 8
EOD
plot $DATA with lines
]])
```

---

##### plot:execute()

Execute all stacked commands and render the plot.

**Returns:**
- `true, nil` on success
- `false, error_message` on error

**Example:**
```lua
plot:cmd("set title 'Test'")
plot:cmd("set grid")
plot:cmd("plot sin(x)")

local success, err = plot:execute()
if not success then
    print("Plot error:", err)
end
```

**Notes:**
- Automatically uses luacmd terminal at current widget size
- Renders to bitmap and displays in panel
- Can be called multiple times to update plot

---

##### plot:clear()

Clear the command stack (keeps the rendered plot visible).

**Example:**
```lua
plot:clear()  -- Clear commands but keep plot displayed
```

---

##### plot:refresh()

Force repaint of the plot widget.

**Example:**
```lua
plot:refresh()
```

---

##### plot:getSize()

Get current widget size.

**Returns:**
- `width, height` (numbers)

**Example:**
```lua
local w, h = plot:getSize()
print("Plot size:", w, "x", h)
```

---

**Complete Plot Widget Example:**

```lua
local wx = require("wx")
local wxgnuplot = require("wxgnuplot")

-- Create frame
local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Gnuplot Widget Example",
    wx.wxDefaultPosition, wx.wxSize(800, 600))

-- Create plot widget
local plot = wxgnuplot.new(frame, wx.wxID_ANY)

-- Add to sizer
local sizer = wx.wxBoxSizer(wx.wxVERTICAL)
sizer:Add(plot:getPanel(), 1, wx.wxEXPAND)
frame:SetSizer(sizer)

-- Set up plot
plot:cmd("set title 'Real-time Plot'")
plot:cmd("set xlabel 'X'")
plot:cmd("set ylabel 'Y'")
plot:cmd("set grid")
plot:cmd("plot sin(x), cos(x)")

-- Render
plot:execute()

-- Show window
frame:Show(true)
wx.wxGetApp():MainLoop()
```

**Widget Features:**
- Automatic resize handling (plot re-renders on window resize)
- Anti-aliased rendering using wxGraphicsContext
- Smooth curves with path accumulation
- Supports all gnuplot plot types
- Event-driven updates

**Using set_datablock with Widget:**

```lua
-- Better than heredoc for widget plots
local data = {}
for i = 1, 100 do
    local x = i / 10
    local y = math.sin(x)
    table.insert(data, string.format("%f %f", x, y))
end

-- Set datablock first (global)
wxgnuplot.set_datablock("$MYDATA", table.concat(data, "\n"))

-- Then use in plot widget
plot:cmd("plot $MYDATA with lines title 'Data'")
plot:execute()
```

---

## Complete Examples

### Example 1: Simple Plot to PNG File (wxgnuplot)

```lua
local wxgnuplot = require("wxgnuplot")

wxgnuplot.init()

-- Configure
wxgnuplot.cmd("set terminal png size 800,600")
wxgnuplot.cmd("set output 'sine_wave.png'")
wxgnuplot.cmd("set title 'Sine Wave'")
wxgnuplot.cmd("set xlabel 'x'")
wxgnuplot.cmd("set ylabel 'sin(x)'")
wxgnuplot.cmd("set grid")

-- Plot
wxgnuplot.cmd("plot sin(x) with lines lw 2")

-- Close output
wxgnuplot.cmd("set output")

wxgnuplot.close()
print("Plot saved to sine_wave.png")
```

### Example 2: Using plot_to_file() Helper

```lua
local wxgnuplot = require("wxgnuplot")

local commands = {
    "set title 'Trigonometric Functions'",
    "set xlabel 'X axis'",
    "set ylabel 'Y axis'",
    "set grid",
    "set key top right",
    "plot sin(x) title 'sin(x)' with lines lw 2, cos(x) title 'cos(x)' with lines lw 2"
}

wxgnuplot.plot_to_file("trig.svg", "svg", "1024x768", commands)
print("Plot saved to trig.svg")
```

### Example 3: PBM RGB Data Display

```lua
local wx = require("wx")
local wxgnuplot = require("wxgnuplot")

-- Create frame
local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "RGB Display",
    wx.wxDefaultPosition, wx.wxSize(800, 600))

local panel = wx.wxPanel(frame, wx.wxID_ANY)
local bitmapCtrl = wx.wxStaticBitmap(panel, wx.wxID_ANY, wx.wxBitmap(640, 480))

-- Generate plot
wxgnuplot.init()
wxgnuplot.cmd("set terminal pbm color size 640,480")
wxgnuplot.cmd("set output '/dev/null'")
wxgnuplot.cmd("set title 'Sine and Cosine'")
wxgnuplot.cmd("set grid")
wxgnuplot.cmd("plot sin(x), cos(x)")

-- Get RGB data
local rgb_data = wxgnuplot.get_pbm_rgb_data()

if rgb_data then
    -- Convert to wxImage
    local image = wx.wxImage(rgb_data.width, rgb_data.height)
    image:SetData(rgb_data.data)

    -- Display
    local bitmap = wx.wxBitmap(image)
    bitmapCtrl:SetBitmap(bitmap)
end

frame:Show(true)
wx.wxGetApp():MainLoop()
```

### Example 4: Plot Widget with Data

```lua
local wx = require("wx")
local wxgnuplot = require("wxgnuplot")

local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Plot Widget",
    wx.wxDefaultPosition, wx.wxSize(800, 600))

-- Create plot
local plot = wxgnuplot.new(frame, wx.wxID_ANY)

-- Add to sizer
local sizer = wx.wxBoxSizer(wx.wxVERTICAL)
sizer:Add(plot:getPanel(), 1, wx.wxEXPAND)
frame:SetSizer(sizer)

-- Generate data
local data_points = {}
for i = 1, 100 do
    local x = (i - 50) / 10
    local y = x * x - 2 * x + 1
    table.insert(data_points, string.format("%f %f", x, y))
end

-- Set datablock
wxgnuplot.set_datablock("$PARABOLA", table.concat(data_points, "\n"))

-- Configure plot
plot:cmd("set title 'Parabola: y = x² - 2x + 1'")
plot:cmd("set xlabel 'x'")
plot:cmd("set ylabel 'y'")
plot:cmd("set grid")
plot:cmd("plot $PARABOLA with lines lw 2 title 'y = x² - 2x + 1'")

-- Render
plot:execute()

frame:Show(true)
wx.wxGetApp():MainLoop()
```

### Example 5: Multiple Output Formats

```lua
local wxgnuplot = require("wxgnuplot")

local plot_commands = {
    "set title 'Multi-Format Plot'",
    "set xlabel 'X'",
    "set ylabel 'Y'",
    "set grid",
    "plot sin(x) title 'sin(x)' with lines lw 2"
}

-- Generate multiple formats
wxgnuplot.plot_to_file("output.pbm", "pbm color", "640x480", plot_commands)
wxgnuplot.plot_to_file("output.png", "png", "640x480", plot_commands)
wxgnuplot.plot_to_file("output.svg", "svg", "640x480", plot_commands)

print("Generated: output.pbm, output.png, output.svg")
```

---

## Error Handling

### gnuplot Module

The gnuplot module functions return boolean values for success/failure:

```lua
local gnuplot = require("gnuplot")

-- init() returns true/false
if not gnuplot.init() then
    print("Failed to initialize gnuplot")
    return
end

-- cmd() returns true/false
if not gnuplot.cmd("plot sin(x)") then
    print("Plot command failed")
end

-- Functions that return data use nil + error message pattern
local result, err = gnuplot.get_commands()
if not result then
    print("Error:", err)
end

local rgb, err = gnuplot.get_pbm_rgb_data()
if not rgb then
    print("RGB data error:", err)
end
```

### wxgnuplot Module

Same error handling as gnuplot module:

```lua
local wxgnuplot = require("wxgnuplot")

-- Check initialization
if not wxgnuplot.is_initialized() then
    wxgnuplot.init()
end

-- Check command results
if not wxgnuplot.cmd("plot sin(x)") then
    print("Command failed")
end

-- plot:execute() returns success, error
local plot = wxgnuplot.new(parent, wx.wxID_ANY)
plot:cmd("plot sin(x)")

local success, err = plot:execute()
if not success then
    print("Plot execution failed:", err)
end
```

---

## See Also

- [Advanced Topics](ADVANCED.md) - Terminal architecture, implementation details
- [examples/](../examples/) - Complete example scripts
- [wxgnuplot.lua](../wxgnuplot.lua) - Module source code
