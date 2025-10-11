#!/home/aryajur/Lua/lua
-- wxgnuplot Demo - Reusable plotting widget demonstration
-- Shows how to embed gnuplot plots in a custom wxLua GUI

-- Add module paths
package.path = package.path .. ";../src/?.lua"
--package.cpath = './?.so;/home/aryajur/Lua/?.so;;'

local wx = require("wx")
local wxgnuplot = require("wxgnuplot")

print("=== wxgnuplot Demo ===\n")

-- Create the main application frame
local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxgnuplot Demo - Embedded Plot Widget",
                         wx.wxDefaultPosition,
                         wx.wxSize(1000, 700),
                         wx.wxDEFAULT_FRAME_STYLE)

-- Create main panel
local mainPanel = wx.wxPanel(frame, wx.wxID_ANY)

-- Create main vertical sizer
local mainSizer = wx.wxBoxSizer(wx.wxVERTICAL)

-- Add title
local title = wx.wxStaticText(mainPanel, wx.wxID_ANY,
    "Reusable gnuplot Widget - Dynamically resize the window!")
local titleFont = wx.wxFont(12, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_BOLD)
title:SetFont(titleFont)
mainSizer:Add(title, 0, wx.wxALL + wx.wxALIGN_CENTER, 10)

-- Create plot widget
print("Creating plot widget...")
local plot = wxgnuplot.new(mainPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(800, 500))

-- Add plot to sizer (expand to fill space)
mainSizer:Add(plot:getPanel(), 1, wx.wxEXPAND + wx.wxALL, 10)

-- Create control panel
local controlPanel = wx.wxPanel(mainPanel, wx.wxID_ANY)
local controlSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)

-- Add buttons
local btnPlot1 = wx.wxButton(controlPanel, wx.wxID_ANY, "Sin/Cos",
                             wx.wxDefaultPosition, wx.wxSize(100, 30))
local btnPlot2 = wx.wxButton(controlPanel, wx.wxID_ANY, "Damped",
                             wx.wxDefaultPosition, wx.wxSize(100, 30))
local btnPlot3 = wx.wxButton(controlPanel, wx.wxID_ANY, "Complex",
                             wx.wxDefaultPosition, wx.wxSize(100, 30))
local btnPlot4 = wx.wxButton(controlPanel, wx.wxID_ANY, "3D Surface",
                             wx.wxDefaultPosition, wx.wxSize(100, 30))
local btnPlot5 = wx.wxButton(controlPanel, wx.wxID_ANY, "Bar Chart",
                             wx.wxDefaultPosition, wx.wxSize(100, 30))
local btnClear = wx.wxButton(controlPanel, wx.wxID_ANY, "Clear",
                             wx.wxDefaultPosition, wx.wxSize(80, 30))
local btnClose = wx.wxButton(controlPanel, wx.wxID_ANY, "Close",
                             wx.wxDefaultPosition, wx.wxSize(80, 30))

controlSizer:Add(btnPlot1, 0, wx.wxALL, 5)
controlSizer:Add(btnPlot2, 0, wx.wxALL, 5)
controlSizer:Add(btnPlot3, 0, wx.wxALL, 5)
controlSizer:Add(btnPlot4, 0, wx.wxALL, 5)
controlSizer:Add(btnPlot5, 0, wx.wxALL, 5)
controlSizer:Add(btnClear, 0, wx.wxALL, 5)
controlSizer:AddStretchSpacer(1)
controlSizer:Add(btnClose, 0, wx.wxALL, 5)

controlPanel:SetSizer(controlSizer)
mainSizer:Add(controlPanel, 0, wx.wxEXPAND + wx.wxALL, 5)

-- Add info text
local info = wx.wxStaticText(mainPanel, wx.wxID_ANY,
    "Try resizing the window - the plot automatically regenerates!")
mainSizer:Add(info, 0, wx.wxALL + wx.wxALIGN_CENTER, 5)

-- Set main sizer
mainPanel:SetSizer(mainSizer)

-- Button event handlers

-- Plot 1: Simple sin/cos
btnPlot1:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    print("Plotting Sin/Cos...")
    plot:clear()
    plot:cmd("reset")
    plot:cmd("set title 'Sine and Cosine Functions'")
    plot:cmd("set xlabel 'x'")
    plot:cmd("set ylabel 'y'")
    plot:cmd("set grid")
    plot:cmd("set key top right box")
    plot:cmd("set xrange [-10:10]")
    plot:cmd("set yrange [-1.5:1.5]")
    plot:cmd("set samples 500")
    plot:cmd("set style line 1 lc rgb '#0060ad' lt 1 lw 2")
    plot:cmd("set style line 2 lc rgb '#dd181f' lt 1 lw 2")
    plot:cmd("plot sin(x) title 'sin(x)' ls 1, cos(x) title 'cos(x)' ls 2")

    local success, err = plot:execute()
    if success then
        print("✓ Plot 1 rendered")
    else
        print("✗ Error:", err)
    end
end)

-- Plot 2: Damped oscillations
btnPlot2:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    print("Plotting Damped Oscillations...")
    plot:clear()
    plot:cmd("reset")
    plot:cmd("set title 'Damped Oscillations'")
    plot:cmd("set xlabel 'Time'")
    plot:cmd("set ylabel 'Amplitude'")
    plot:cmd("set grid")
    plot:cmd("set key top right box")
    plot:cmd("set xrange [0:10]")
    plot:cmd("set yrange [-1:1]")
    plot:cmd("set samples 500")
    plot:cmd("set style line 1 lc rgb '#00ad60' lt 1 lw 2")
    plot:cmd("set style line 2 lc rgb '#ad6000' lt 1 lw 2")
    plot:cmd("set style line 3 lc rgb '#6000ad' lt 1 lw 2")
    plot:cmd("plot sin(x)*exp(-x/10) title 'Fast decay' ls 1, sin(x)*exp(-x/20) title 'Slow decay' ls 2, exp(-x/10) title 'Envelope' ls 3")

    local success, err = plot:execute()
    if success then
        print("✓ Plot 2 rendered")
    else
        print("✗ Error:", err)
    end
end)

-- Plot 3: Complex multi-function plot
btnPlot3:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    print("Plotting Complex Functions...")
    plot:clear()
    plot:cmd("reset")
    plot:cmd("set title 'Beautiful Mathematical Functions'")
    plot:cmd("set xlabel 'x'")
    plot:cmd("set ylabel 'y'")
    plot:cmd("set grid lw 1")
    plot:cmd("set key top right box")
    plot:cmd("set xrange [-10:10]")
    plot:cmd("set yrange [-5:5]")
    plot:cmd("set samples 500")
    plot:cmd("set style line 1 lc rgb '#0060ad' lt 1 lw 2")
    plot:cmd("set style line 2 lc rgb '#dd181f' lt 1 lw 2")
    plot:cmd("set style line 3 lc rgb '#00ad60' lt 1 lw 2")
    plot:cmd("set style line 4 lc rgb '#ad6000' lt 1 lw 2")
    plot:cmd("plot sin(x) title 'sin(x)' ls 1, cos(x) title 'cos(x)' ls 2, sin(x)*exp(-x/10) title 'damped sine' ls 3, x/10 title 'x/10' ls 4")

    local success, err = plot:execute()
    if success then
        print("✓ Plot 3 rendered")
    else
        print("✗ Error:", err)
    end
end)

-- Plot 4: 3D Surface
btnPlot4:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    print("Plotting 3D Surface...")
    plot:clear()
    plot:cmd("reset")
    plot:cmd("set title '3D Surface: sin(x)*cos(y)'")
    plot:cmd("set xlabel 'X axis'")
    plot:cmd("set ylabel 'Y axis'")
    plot:cmd("set zlabel 'Z axis'")
    plot:cmd("unset pm3d")  -- Disable pm3d to use line colors
    plot:cmd("set hidden3d")
    plot:cmd("set grid")
    plot:cmd("set samples 30")
    plot:cmd("set isosamples 30")
    plot:cmd("set xrange [-3:3]")
    plot:cmd("set yrange [-3:3]")
    plot:cmd("set zrange [-1:1]")
    plot:cmd("set xyplane at -1")
    -- Redefine line types to use our colors
    plot:cmd("set linetype 1 lc rgb '#0060ad' lw 2")
    plot:cmd("set linetype 2 lc rgb '#dd181f' lw 2")
    plot:cmd("splot sin(x)*cos(y) title 'Surface' with lines")

    local success, err = plot:execute()
    if success then
        print("✓ Plot 4 rendered (3D Surface)")
    else
        print("✗ Error:", err)
    end
end)

-- Plot 5: Bar Chart (using boxxyerrorbars with explicit rectangles)
btnPlot5:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    print("Plotting Bar Chart...")
    plot:clear()
    plot:cmd("reset")
    plot:cmd("set title 'Monthly Sales Data'")
    plot:cmd("set xlabel 'Month'")
    plot:cmd("set ylabel 'Sales (thousands)'")
    plot:cmd("set style fill solid 0.5 border")
    plot:cmd("set grid ytics")
    plot:cmd("set xtics ('Jan' 0, 'Feb' 1, 'Mar' 2, 'Apr' 3, 'May' 4, 'Jun' 5)")
    plot:cmd("set xrange [-0.5:5.5]")
    plot:cmd("set yrange [0:100]")
    plot:cmd("set style line 1 lc rgb '#0060ad'")
    plot:cmd("set style line 2 lc rgb '#dd181f'")
    plot:cmd("set key top left box")

    -- Use object rectangles for bars with correct syntax
    plot:cmd("set object 1 rect from -0.15,0 to 0.15,45 fc rgb '#0060ad' fs solid")
    plot:cmd("set object 2 rect from 0.85,0 to 1.15,67 fc rgb '#0060ad' fs solid")
    plot:cmd("set object 3 rect from 1.85,0 to 2.15,82 fc rgb '#0060ad' fs solid")
    plot:cmd("set object 4 rect from 2.85,0 to 3.15,71 fc rgb '#0060ad' fs solid")
    plot:cmd("set object 5 rect from 3.85,0 to 4.15,88 fc rgb '#0060ad' fs solid")
    plot:cmd("set object 6 rect from 4.85,0 to 5.15,92 fc rgb '#0060ad' fs solid")

    plot:cmd("set object 7 rect from 0.15,0 to 0.45,38 fc rgb '#dd181f' fs solid")
    plot:cmd("set object 8 rect from 1.15,0 to 1.45,52 fc rgb '#dd181f' fs solid")
    plot:cmd("set object 9 rect from 2.15,0 to 2.45,69 fc rgb '#dd181f' fs solid")
    plot:cmd("set object 10 rect from 3.15,0 to 3.45,58 fc rgb '#dd181f' fs solid")
    plot:cmd("set object 11 rect from 4.15,0 to 4.45,74 fc rgb '#dd181f' fs solid")
    plot:cmd("set object 12 rect from 5.15,0 to 5.45,81 fc rgb '#dd181f' fs solid")

    -- Create dummy plots for legend (plot invisible points outside range with proper titles)
    plot:cmd("plot -1 with boxes lc rgb '#0060ad' title 'Product A', -1 with boxes lc rgb '#dd181f' title 'Product B'")

    local success, err = plot:execute()
    if success then
        print("✓ Plot 5 rendered (Bar Chart)")
    else
        print("✗ Error:", err)
    end
end)

-- Clear button
btnClear:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    print("Clearing plot...")
    plot:clear()
    -- Create a blank white bitmap
    local width, height = plot:getSize()
    local bitmap = wx.wxBitmap(width, height, 32)
    local memDC = wx.wxMemoryDC()
    memDC:SelectObject(bitmap)
    memDC:SetBackground(wx.wxWHITE_BRUSH)
    memDC:Clear()
    memDC:SelectObject(wx.wxNullBitmap)
    -- Set the blank bitmap
    plot.bitmap = bitmap
    plot:refresh()
    print("✓ Plot cleared")
end)

-- Close button
btnClose:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    frame:Close(true)
end)

-- Show initial plot
print("Rendering initial plot...")
plot:cmd("reset")
plot:cmd("set title 'Welcome to wxgnuplot Widget!'")
plot:cmd("set xlabel 'x'")
plot:cmd("set ylabel 'y'")
plot:cmd("set grid")
plot:cmd("set key top right box")
plot:cmd("set xrange [-10:10]")
plot:cmd("set yrange [-1.5:1.5]")
plot:cmd("set samples 500")
plot:cmd("set style line 1 lc rgb '#0060ad' lt 1 lw 2")
plot:cmd("plot sin(x) title 'sin(x)' ls 1")

local success, err = plot:execute()
if not success then
    print("Error rendering initial plot:", err)
    wx.wxMessageBox("Failed to render plot: " .. (err or "unknown error"),
                   "Error", wx.wxOK + wx.wxICON_ERROR, frame)
end

-- Show frame
frame:Show(true)
frame:Raise()

print("✓ Application ready!")
print("\nFeatures:")
print("  - Plot widget embedded in custom GUI")
print("  - Dynamically resizes with window")
print("  - Command stacking for flexible plotting")
print("  - Multiple plot presets (2D, 3D, and bar charts)")
print("\nTry the different plot buttons and resize the window!\n")

-- Start event loop
wx.wxGetApp():MainLoop()
print("Done!")
