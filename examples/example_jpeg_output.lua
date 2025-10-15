#!/usr/bin/env lua
-- Example: Generate plot to JPEG (Joint Photographic Experts Group) file
-- JPEG requires libgd library

local wxgnuplot = require("wxgnuplot")

print("=== JPEG File Output Example ===\n")

-- Initialize gnuplot
wxgnuplot.init()
print("Gnuplot version: " .. wxgnuplot.version())

-- Try to set JPEG terminal
local success = wxgnuplot.cmd("set terminal jpeg size 640,480")

if not success then
    print("\nERROR: JPEG terminal not available")
    print("Install libgd-dev (Debian/Ubuntu) or libgd-devel (RedHat/Fedora)")
    print("Then rebuild gnuplot with: ./build.sh")
    os.exit(1)
end

-- Set output file
wxgnuplot.cmd("set output 'output.jpg'")

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

print("\nPlot saved to: output.jpg")
print("\nJPEG format:")
print("  - Lossy compression")
print("  - NOT recommended for plots (artifacts around lines/text)")
print("  - Best for photographs, not diagrams")
print("  - Small file size")
print("  - Use PNG instead for better quality plots")
print("  - Requires libgd library")
