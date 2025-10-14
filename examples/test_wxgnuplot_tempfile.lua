#!/home/aryajur/Lua/lua
-- Test wxgnuplot with data from temp file (like lua-plot does)

package.path = package.path .. ";../src/?.lua"
package.cpath = package.cpath .. ";/home/aryajur/Lua/?.so"

local wx = require("wx")
local wxgnuplot = require("wxgnuplot")

print("=== wxgnuplot Test with Temp File Data ===")

-- Generate sine wave data points
print("Generating data points...")
local data = {}
for i = -31, 31 do
    local x = i * 0.2
    local y = math.sin(x)
    data[#data+1] = {x, y}
end
print(string.format("Generated %d data points", #data))

-- Write to temp file
local tempfile = os.tmpname() .. ".dat"
print("Writing to temp file:", tempfile)
local f = io.open(tempfile, "w")
for i = 1, #data do
    f:write(string.format("%.15g %.15g\n", data[i][1], data[i][2]))
end
f:close()

-- Create frame
local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Sine Wave from Temp File",
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

-- Queue gnuplot commands using temp file
print("Queueing commands...")
plot:cmd("reset")
plot:cmd("set title 'Sine Wave from Temp File'")
plot:cmd("set xlabel 'x'")
plot:cmd("set ylabel 'y'")
plot:cmd("set grid")
plot:cmd(string.format("plot '%s' using 1:2 with lines lw 2 title 'sin(x)'", tempfile))

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

-- Cleanup on close
frame:Connect(wx.wxEVT_CLOSE_WINDOW, function(event)
    print("Cleaning up temp file...")
    os.remove(tempfile)
    event:Skip()
    frame:Destroy()
end)

-- Start event loop
wx.wxGetApp():MainLoop()
print("Done!")
