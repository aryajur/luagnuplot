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
                         wx.wxSize(900, 700),
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
local btnPlot1 = wx.wxButton(controlPanel, wx.wxID_ANY, "Plot 1: Sin/Cos",
                             wx.wxDefaultPosition, wx.wxSize(120, 30))
local btnPlot2 = wx.wxButton(controlPanel, wx.wxID_ANY, "Plot 2: Damped",
                             wx.wxDefaultPosition, wx.wxSize(120, 30))
local btnPlot3 = wx.wxButton(controlPanel, wx.wxID_ANY, "Plot 3: Complex",
                             wx.wxDefaultPosition, wx.wxSize(120, 30))
local btnClear = wx.wxButton(controlPanel, wx.wxID_ANY, "Clear Commands",
                             wx.wxDefaultPosition, wx.wxSize(120, 30))
local btnClose = wx.wxButton(controlPanel, wx.wxID_ANY, "Close",
                             wx.wxDefaultPosition, wx.wxSize(120, 30))

controlSizer:Add(btnPlot1, 0, wx.wxALL, 5)
controlSizer:Add(btnPlot2, 0, wx.wxALL, 5)
controlSizer:Add(btnPlot3, 0, wx.wxALL, 5)
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

-- Clear button
btnClear:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    print("Clearing command stack...")
    plot:clear()
    print("✓ Command stack cleared (plot remains visible)")
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
print("  - Multiple plot presets")
print("\nTry resizing the window!\n")

-- Start event loop
wx.wxGetApp():MainLoop()
print("Done!")
