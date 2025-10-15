#!/usr/bin/env lua
-- Example: Display PBM RGB data in a wxLua window
-- Shows how to get raw RGB data from gnuplot and display it

local wx = require("wx")
local wxgnuplot = require("wxgnuplot")

-- Create main frame
local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Gnuplot PBM RGB Display Example",
    wx.wxDefaultPosition, wx.wxSize(800, 600))

-- Create panel
local panel = wx.wxPanel(frame, wx.wxID_ANY)
local sizer = wx.wxBoxSizer(wx.wxVERTICAL)

-- Add label
local label = wx.wxStaticText(panel, wx.wxID_ANY,
    "Displaying gnuplot output as raw RGB bitmap from PBM terminal")
sizer:Add(label, 0, wx.wxALL + wx.wxALIGN_CENTER, 10)

-- Create a static bitmap to display the image
local bitmapCtrl = wx.wxStaticBitmap(panel, wx.wxID_ANY,
    wx.wxBitmap(400, 300))
sizer:Add(bitmapCtrl, 1, wx.wxALL + wx.wxEXPAND, 10)

-- Add button to regenerate plot
local button = wx.wxButton(panel, wx.wxID_ANY, "Generate New Plot")
sizer:Add(button, 0, wx.wxALL + wx.wxALIGN_CENTER, 10)

panel:SetSizer(sizer)

-- Function to create and display plot
local function generate_plot()
    -- Initialize gnuplot
    if not wxgnuplot.is_initialized() then
        wxgnuplot.init()
    end

    -- Set PBM terminal with desired size
    local width, height = 640, 480
    wxgnuplot.cmd(string.format("set terminal pbm color size %d,%d", width, height))

    -- Use temp file for output (works cross-platform)
    -- The bitmap is captured by terminal hook BEFORE file I/O, so minimal overhead
	-- On Linux temp_file can be '/dev/null' 
	-- On windows 'NUL' is equivalent of /dev/null but does not work since all characters are then printed to terminal and takes long time.
    local temp_file = os.tmpname() .. ".pbm"
    wxgnuplot.cmd(string.format("set output '%s'", temp_file))

    -- Create a nice plot
    wxgnuplot.cmd("set title 'Sine and Cosine Waves'")
    wxgnuplot.cmd("set xlabel 'X axis'")
    wxgnuplot.cmd("set ylabel 'Y axis'")
    wxgnuplot.cmd("set grid")
    wxgnuplot.cmd("set key top right")

    -- Plot multiple functions
    wxgnuplot.cmd("plot sin(x) title 'sin(x)' with lines lw 2, " ..
                  "cos(x) title 'cos(x)' with lines lw 2")

    -- Get RGB data (captured by terminal hook before file is written)
    local rgb_data, err = wxgnuplot.get_pbm_rgb_data()

    -- Clean up temp file (bitmap already captured in memory)
    pcall(os.remove, temp_file)

    if not rgb_data then
        wx.wxMessageBox("Failed to get RGB data:\n" .. (err or "unknown error"),
            "Error", wx.wxOK + wx.wxICON_ERROR)
        return
    end

    print(string.format("Got RGB data: %dx%d, %d bytes",
        rgb_data.width, rgb_data.height, #rgb_data.data))

    -- Convert RGB data to wxImage
    local image = wx.wxImage(rgb_data.width, rgb_data.height)
    image:SetData(rgb_data.data)

    -- Convert to bitmap and display
    local bitmap = wx.wxBitmap(image)
    bitmapCtrl:SetBitmap(bitmap)

    -- Update status
    label:SetLabel(string.format("Displaying %dx%d plot (RGB data: %d bytes)",
        rgb_data.width, rgb_data.height, #rgb_data.data))

    panel:Layout()
end

-- Button click handler
button:Connect(wx.wxEVT_BUTTON, function(event)
    generate_plot()
end)

-- Generate initial plot
generate_plot()

-- Show frame
frame:Show(true)

-- Start event loop
wx.wxGetApp():MainLoop()
