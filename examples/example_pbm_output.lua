#!/usr/bin/env lua
-- Example: Generate plot to PBM (Portable Bitmap) file
-- PBM is a simple bitmap format, always available

local wxgnuplot = require("wxgnuplot")

print("=== PBM File Output Example ===\n")

-- Initialize gnuplot
wxgnuplot.init()
print("Gnuplot version: " .. wxgnuplot.version())

-- Set PBM terminal with size
wxgnuplot.cmd("set terminal pbm color size 640,480")
wxgnuplot.cmd("set output 'output.pbm'")

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

print("\nPlot saved to: output.pbm")
print("\nPBM format:")
print("  - Simple bitmap format")
print("  - Always available (no external libraries needed)")
print("  - Larger file size (uncompressed)")
print("  - Can be converted to other formats with ImageMagick:")
print("    convert output.pbm output.png")
