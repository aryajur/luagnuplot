# Gnuplot Library with Lua Bindings

This project modifies gnuplot to compile as a shared library and provides Lua bindings for creating plots programmatically from Lua scripts.

## Overview

Instead of using gnuplot as a terminal application, this modification allows you to:
- Compile gnuplot as a shared library (`libgnuplot.so` or `libgnuplot.dll`)
- Use gnuplot directly from Lua scripts via the `gnuplot` module
- Pass gnuplot commands as strings to generate plots
- Access plot data directly (wxLua terminal, RGB data)

## Project Structure

```
.
├── README.md                  # This file
├── docs/                      # Documentation
│   ├── API.md                # Lua module API reference
│   └── ADVANCED.md           # Advanced topics and terminal architecture
├── terminal/                 # Custom terminal drivers
│   └── wxlua.trm             # wxLua terminal implementation
├── src/                      # Library wrapper code
│   ├── libgnuplot.h          # Library interface header
│   └── libgnuplot.c          # Library implementation
├── patches/                  # Patches for gnuplot source
│   ├── README.md             # Patch documentation
│   └── term.h.patch          # Adds wxlua terminal to term.h
├── examples/                 # Example Lua scripts
│   ├── examples.lua          # Basic usage examples
│   └── wxlua_plot_perfect.lua # wxLua terminal demo (optimized rendering)
├── build/                    # Build artifacts (created by build.sh)
│   ├── inc/                  # Lua headers (for Windows/MinGW)
│   ├── lib/                  # Lua libraries (for Windows/MinGW)
│   ├── config/               # Generated config.h
│   └── *.o                   # Compiled object files
├── gnuplot-source/           # Gnuplot source (cloned by build.sh)
├── lua_gnuplot.c             # Lua bindings for libgnuplot
├── build.sh                  # Build script (Linux and Windows/MinGW)
├── libgnuplot.so             # Compiled gnuplot library
└── gnuplot.so                # Compiled Lua module
```

## Quick Start

### Prerequisites

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install build-essential lua5.4 liblua5.4-dev libreadline-dev
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install gcc make lua lua-devel readline-devel
```

**Windows (MinGW/MSYS2):**
```bash
pacman -S mingw-w64-x86_64-gcc make mingw-w64-x86_64-lua
```

### Building on Linux

```bash
# Build the library and Lua bindings
# The script will automatically clone gnuplot source if needed
./build.sh

# Built files:
# - libgnuplot.so (1.9MB) - Main gnuplot library
# - gnuplot.so (70KB) - Lua module
```

**For Linux:** Lua development packages are detected from system paths automatically.

### Building on Windows/MinGW

```bash
# For Windows/MinGW, first place Lua files in build directory:
# 1. Create build/inc/ and place Lua header files (lua.h, etc.)
# 2. Create build/lib/ and place Lua library files (lua54.dll, etc.)

# Then run the build script
./build.sh

# Built files:
# - libgnuplot.dll - Main gnuplot library
# - gnuplot.dll - Lua module
```

**Note:** The build script works on both Linux and Windows/MinGW without requiring autotools.

### Using the Lua Module

```lua
-- Set up library path
package.cpath = './?.so;;'  -- Linux
-- package.cpath = './?.dll;;'  -- Windows

local gnuplot = require("gnuplot")

-- Initialize gnuplot
gnuplot.init()

-- Create a simple plot to SVG file
gnuplot.cmd("set terminal svg size 800,600")
gnuplot.cmd("set output 'plot.svg'")
gnuplot.cmd("plot sin(x)")

-- Close gnuplot
gnuplot.close()
```

See `examples/examples.lua` for more usage examples.

## Basic Examples

### 1. Plot to SVG File

```lua
local gnuplot = require("gnuplot")

gnuplot.init()
gnuplot.cmd("set terminal svg size 800,600")
gnuplot.cmd("set output 'myplot.svg'")
gnuplot.cmd("set title 'Simple Plot'")
gnuplot.cmd("plot sin(x), cos(x)")
gnuplot.close()
```

### 2. Multiple Plots

```lua
local gnuplot = require("gnuplot")

gnuplot.init()
gnuplot.cmd("set terminal png size 1024,768")

-- First plot
gnuplot.cmd("set output 'plot1.png'")
gnuplot.cmd("plot x**2")

-- Second plot
gnuplot.cmd("set output 'plot2.png'")
gnuplot.cmd("plot sin(x)*exp(-x/10)")

gnuplot.close()
```

### 3. Using wxLua Terminal (Interactive Display)

```lua
package.cpath = './?.so;/home/your_user/Lua/?.so;;'

local gnuplot = require("gnuplot")
local wx = require("wx")

gnuplot.init()
gnuplot.cmd("set terminal wxlua size 1000,700")
gnuplot.cmd("set title 'Interactive Plot'")
gnuplot.cmd("plot sin(x), cos(x)")

-- Get drawing commands
local result = gnuplot.get_commands()
gnuplot.close()

-- Render to wxLua window
-- (See examples/wxlua_plot_perfect.lua for complete example)
```

## Available Terminals

The library supports all standard gnuplot terminals:

- **svg** - Scalable Vector Graphics
- **png** - PNG raster images
- **pngcairo** - High-quality PNG with Cairo
- **pdf** - PDF documents
- **postscript** - PostScript files
- **canvas** - HTML5 canvas
- **wxlua** - Direct wxLua rendering (custom terminal)

## Environment Setup

### Linux
```bash
export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
export LUA_CPATH='./?.so;;'
```

### Windows
```bash
export PATH=.:$PATH
set LUA_CPATH=./?.dll;;
```

## Troubleshooting

### "module 'gnuplot' not found"
- Ensure `gnuplot.so` (or `.dll`) is in the current directory or in your `LUA_CPATH`
- Check: `lua -e "print(package.cpath)"`

### "libgnuplot.so: cannot open shared object file"
- Set `LD_LIBRARY_PATH` to include the current directory:
  ```bash
  export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
  ```

### Build errors on Windows
- Use `build_mingw.sh` instead of `build.sh`
- Ensure MinGW/MSYS2 is properly installed
- Install required packages: `gcc`, `make`, `lua`

## Documentation

- **[API Reference](docs/API.md)** - Complete Lua module API documentation
- **[Advanced Topics](docs/ADVANCED.md)** - Terminal architecture, RGB feature, wxLua terminal

## License

This project uses the gnuplot source code, which is licensed under the gnuplot license. The modifications and Lua bindings follow the same license terms.

## Credits

- **Gnuplot** - Original plotting software (http://www.gnuplot.info/)
- **Lua bindings** - Custom wrapper for library integration
- **wxLua terminal** - Custom terminal for direct GUI rendering
