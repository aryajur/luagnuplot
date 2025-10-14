#!/home/aryajur/Lua/lua
-- Minimal wxgnuplot test - just like wxgnuplot_demo.lua

package.path = package.path .. ";../src/?.lua"
package.cpath = package.cpath .. ";/home/aryajur/Lua/?.so"

local wx = require("wx")
local wxgnuplot = require("wxgnuplot")

print("=== Minimal wxgnuplot Test ===")

-- Create frame
local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Sine Wave Test",
                         wx.wxDefaultPosition,
                         wx.wxSize(800, 600),
                         wx.wxDEFAULT_FRAME_STYLE)

-- Create main sizer
local mainSizer = wx.wxBoxSizer(wx.wxVERTICAL)

-- Create wxgnuplot widget
print("Creating wxgnuplot widget...")
local plot = wxgnuplot.new(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(780, 580))

-- Add to sizer
mainSizer:Add(plot:getPanel(), 1, wx.wxEXPAND + wx.wxALL, 10)
frame:SetSizer(mainSizer)
frame:Layout()

-- Queue gnuplot commands (NO temp files - just gnuplot functions)
print("Queueing commands...")
plot:cmd("reset")
plot:cmd("set title 'Simple Sine Wave'")
plot:cmd("set xlabel 'x'")
plot:cmd("set ylabel 'y'")
plot:cmd("set grid")
plot:cmd("set samples 500")
plot:cmd("plot sin(x) with lines lw 2 title 'sin(x)'")

-- Execute
print("Executing...")
local success, err = plot:execute()

if success then
    print("✓ Plot rendered successfully")
else
    print("✗ Error:", err)
end

-- Show frame
frame:Show(true)
frame:Raise()

print("\nFrame shown - try resizing the window!")
print("Close window to exit")

-- Start event loop
wx.wxGetApp():MainLoop()
print("Done!")
