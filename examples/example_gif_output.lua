#!/usr/bin/env lua
-- Example: Generate plot to GIF (Graphics Interchange Format) file
-- GIF requires libgd library

local wxgnuplot = require("wxgnuplot")

print("=== GIF File Output Example ===\n")

-- Initialize gnuplot
wxgnuplot.init()
print("Gnuplot version: " .. wxgnuplot.version())

-- Try to set GIF terminal
local success = wxgnuplot.cmd("set terminal gif size 640,480")

if not success then
    print("\nERROR: GIF terminal not available")
    print("Install libgd-dev (Debian/Ubuntu) or libgd-devel (RedHat/Fedora)")
    print("Then rebuild gnuplot with: ./build.sh")
    os.exit(1)
end

-- Set output file
wxgnuplot.cmd("set output 'output.gif'")

-- Configure plot
wxgnuplot.cmd("set title 'Sine and Cosine Waves'")
wxgnuplot.cmd("set xlabel 'X axis'")
wxgnuplot.cmd("set ylabel 'Y axis'")
wxgnuplot.cmd("set grid")
wxgnuplot.cmd("set key top right")

-- Create the plot
wxgnuplot.cmd("plot sin(x) title 'sin(x)' with lines lw 2, cos(x) title 'cos(x)' with lines lw 2")

-- Close output file
wxgnuplot.cmd("set output")

print("\nPlot saved to: output.gif")
print("\nGIF format:")
print("  - Lossless compression (256 colors)")
print("  - Limited color palette")
print("  - Small file size")
print("  - Supports transparency")
print("  - Supports animation (for multi-frame plots)")
print("  - Requires libgd library")
