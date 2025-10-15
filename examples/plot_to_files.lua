#!/usr/bin/env lua
-- Example: Generate plots to different file formats
-- Demonstrates PBM, PNG, GIF, and JPEG output

local wxgnuplot = require("wxgnuplot")

print("=== Gnuplot File Output Examples ===\n")

-- Initialize gnuplot once
wxgnuplot.init()
print("Gnuplot version: " .. wxgnuplot.version())
print()

-- Common plot setup
local plot_commands = {
    "set title 'Trigonometric Functions'",
    "set xlabel 'X axis'",
    "set ylabel 'Y axis'",
    "set grid",
    "set key top right",
    "plot sin(x) title 'sin(x)' with lines lw 2, cos(x) title 'cos(x)' with lines lw 2"
}

-- Example 1: PBM (Portable Bitmap) output
print("Example 1: Generating PBM file...")
wxgnuplot.cmd("set terminal pbm color size 640,480")
wxgnuplot.cmd("set output 'output_pbm.pbm'")
for _, cmd in ipairs(plot_commands) do
    wxgnuplot.cmd(cmd)
end
wxgnuplot.cmd("set output")
print("  ✓ Created: output_pbm.pbm")
print()

-- Example 2: PNG (Portable Network Graphics) output
print("Example 2: Generating PNG file...")
local png_available = wxgnuplot.cmd("set terminal png size 640,480")
if png_available then
    wxgnuplot.cmd("set output 'output_png.png'")
    for _, cmd in ipairs(plot_commands) do
        wxgnuplot.cmd(cmd)
    end
    wxgnuplot.cmd("set output")
    print("  ✓ Created: output_png.png")
else
    print("  ✗ PNG terminal not available (install libgd)")
end
print()

-- Example 3: GIF (Graphics Interchange Format) output
print("Example 3: Generating GIF file...")
local gif_available = wxgnuplot.cmd("set terminal gif size 640,480")
if gif_available then
    wxgnuplot.cmd("set output 'output_gif.gif'")
    for _, cmd in ipairs(plot_commands) do
        wxgnuplot.cmd(cmd)
    end
    wxgnuplot.cmd("set output")
    print("  ✓ Created: output_gif.gif")
else
    print("  ✗ GIF terminal not available (install libgd)")
end
print()

-- Example 4: JPEG output
print("Example 4: Generating JPEG file...")
local jpeg_available = wxgnuplot.cmd("set terminal jpeg size 640,480")
if jpeg_available then
    wxgnuplot.cmd("set output 'output_jpeg.jpg'")
    for _, cmd in ipairs(plot_commands) do
        wxgnuplot.cmd(cmd)
    end
    wxgnuplot.cmd("set output")
    print("  ✓ Created: output_jpeg.jpg")
else
    print("  ✗ JPEG terminal not available (install libgd)")
end
print()

-- Example 5: Using plot_to_file helper function
print("Example 5: Using plot_to_file() helper...")
wxgnuplot.plot_to_file("output_helper.pbm", "pbm color", "800x600",
    plot_commands)
print("  ✓ Created: output_helper.pbm (using helper function)")
print()

-- Example 6: SVG (Scalable Vector Graphics) output
print("Example 6: Generating SVG file...")
wxgnuplot.cmd("set terminal svg size 640,480")
wxgnuplot.cmd("set output 'output_svg.svg'")
for _, cmd in ipairs(plot_commands) do
    wxgnuplot.cmd(cmd)
end
wxgnuplot.cmd("set output")
print("  ✓ Created: output_svg.svg")
print()

print("=== Summary ===")
print("Generated plots in multiple formats:")
print("  - PBM:  output_pbm.pbm  (bitmap, always available)")
print("  - PNG:  output_png.png  (compressed, requires libgd)")
print("  - GIF:  output_gif.gif  (compressed, requires libgd)")
print("  - JPEG: output_jpeg.jpg (lossy, requires libgd)")
print("  - SVG:  output_svg.svg  (vector, always available)")
print()
print("Use 'ls -lh output_*' to see file sizes")
