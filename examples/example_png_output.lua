#!/usr/bin/env lua
-- Example: Generate plot to PNG (Portable Network Graphics) file
-- PNG requires libgd library

local wxgnuplot = require("wxgnuplot")

print("=== PNG File Output Example ===\n")

-- Initialize gnuplot
wxgnuplot.init()
print("Gnuplot version: " .. wxgnuplot.version())

-- Try to set PNG terminal
local success = wxgnuplot.cmd("set terminal png size 640,480")

if not success then
    print("\nERROR: PNG terminal not available")
    print("Install libgd-dev (Debian/Ubuntu) or libgd-devel (RedHat/Fedora)")
    print("Then rebuild gnuplot with: ./build.sh")
    os.exit(1)
end

-- Set output file
wxgnuplot.cmd("set output 'output.png'")

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

print("\nPlot saved to: output.png")
print("\nPNG format:")
print("  - Lossless compression")
print("  - Good for plots and diagrams")
print("  - Smaller file size than PBM")
print("  - Widely supported")
print("  - Requires libgd library")
