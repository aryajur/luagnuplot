#!/usr/bin/env lua
-- Examples of using gnuplot from Lua

local gp = require("gnuplot")

-- Initialize
gp.init()

print("Gnuplot Lua Bindings - Examples")
print("================================\n")

-- Example 1: Simple function plot
print("Example 1: Simple sine wave")
gp.cmd_multi([[
set terminal png size 800,600
set output 'example1_sine.png'
set title 'Sine Wave'
set xlabel 'x'
set ylabel 'sin(x)'
set grid
plot sin(x) with lines linewidth 2
]])
print("  → Created: example1_sine.png\n")

-- Example 2: Multiple functions
print("Example 2: Multiple trigonometric functions")
gp.cmd_multi([[
set terminal png size 1000,600
set output 'example2_trig.png'
set title 'Trigonometric Functions'
set xlabel 'x'
set ylabel 'y'
set grid
set key top right
plot [-2*pi:2*pi] \
    sin(x) title 'sin(x)' with lines lw 2, \
    cos(x) title 'cos(x)' with lines lw 2, \
    sin(x)*cos(x) title 'sin(x)*cos(x)' with lines lw 2
]])
print("  → Created: example2_trig.png\n")

-- Example 3: Parametric plot
print("Example 3: Parametric plot (circle)")
gp.cmd_multi([[
set terminal png size 800,800
set output 'example3_parametric.png'
set title 'Parametric Circle'
set parametric
set trange [0:2*pi]
set size square
set xrange [-1.5:1.5]
set yrange [-1.5:1.5]
set grid
plot cos(t), sin(t) with lines lw 2 title 'Unit Circle'
unset parametric
]])
print("  → Created: example3_parametric.png\n")

-- Example 4: 3D surface plot
print("Example 4: 3D surface plot")
gp.cmd_multi([[
set terminal png size 800,600
set output 'example4_3d.png'
set title '3D Surface: z = sin(sqrt(x²+y²))'
set xlabel 'x'
set ylabel 'y'
set zlabel 'z'
set hidden3d
set grid
splot [-5:5][-5:5] sin(sqrt(x**2 + y**2)) with lines
]])
print("  → Created: example4_3d.png\n")

-- Example 5: Data plot with inline data
print("Example 5: Bar chart from data")
gp.cmd_multi([[
set terminal png size 800,600
set output 'example5_barchart.png'
set title 'Monthly Sales'
set xlabel 'Month'
set ylabel 'Sales ($1000)'
set style data histograms
set style fill solid
set boxwidth 0.5
set grid ytics
$SALES << EOD
Jan 45
Feb 52
Mar 61
Apr 58
May 67
Jun 72
EOD
plot $SALES using 2:xtic(1) title 'Sales' linecolor rgb '#4285F4'
]])
print("  → Created: example5_barchart.png\n")

-- Example 6: Scatter plot
print("Example 6: Scatter plot with noise")
gp.cmd_multi([[
set terminal png size 800,600
set output 'example6_scatter.png'
set title 'Scatter Plot'
set xlabel 'x'
set ylabel 'y'
set grid
# Generate some random-looking data
plot [-10:10] x + 2*sin(x*0.5) + 0.5*sin(x*5) with points pt 7 ps 0.5 title 'Data'
]])
print("  → Created: example6_scatter.png\n")

-- Example 7: Filled curves
print("Example 7: Filled area plot")
gp.cmd_multi([[
set terminal png size 800,600
set output 'example7_filled.png'
set title 'Filled Area Under Curve'
set xlabel 'x'
set ylabel 'y'
set grid
set style fill solid 0.3
plot [0:2*pi] sin(x) with filledcurves y=0 title 'sin(x)', \
              sin(x) with lines lw 2 linecolor rgb 'blue' notitle
]])
print("  → Created: example7_filled.png\n")

-- Example 8: Heatmap / Matrix plot
print("Example 8: Heatmap")
gp.cmd_multi([[
set terminal png size 800,600
set output 'example8_heatmap.png'
set title 'Heatmap: z = x² + y²'
set xlabel 'x'
set ylabel 'y'
set pm3d map
set palette rgbformulae 33,13,10
splot [-5:5][-5:5] x**2 + y**2
]])
print("  → Created: example8_heatmap.png\n")

-- Example 9: Multiple plots in one (multiplot)
print("Example 9: Multiplot layout")
gp.cmd_multi([[
set terminal png size 1200,800
set output 'example9_multiplot.png'
set multiplot layout 2,2 title "Multiple Plots"

set title 'Plot 1: sin(x)'
plot sin(x) with lines

set title 'Plot 2: cos(x)'
plot cos(x) with lines

set title 'Plot 3: tan(x)'
set yrange [-5:5]
plot tan(x) with lines

set title 'Plot 4: exp(x)'
set yrange [*:*]
plot exp(-x) with lines

unset multiplot
]])
print("  → Created: example9_multiplot.png\n")

-- Example 10: Polar plot
print("Example 10: Polar plot (rose)")
gp.cmd_multi([[
set terminal png size 800,800
set output 'example10_polar.png'
set title 'Polar Plot: Rose Curve'
set polar
set grid polar
set size square
set angle degrees
set trange [0:360]
plot 2*sin(3*t) with lines lw 2 title 'r = 2*sin(3θ)'
unset polar
]])
print("  → Created: example10_polar.png\n")

-- Clean up
gp.close()

print("All examples completed!")
print("\nGenerated 10 example plots:")
for i = 1, 10 do
    print(string.format("  • example%d_*.png", i))
end
