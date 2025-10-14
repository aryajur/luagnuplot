#!/usr/bin/env wlua
-- wxgnuplot data block example
-- Demonstrates using inline data blocks with wxgnuplot

local wx = require("wx")
local wxgnuplot = require("wxgnuplot")

-- Create main application frame
local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxgnuplot Data Block Demo",
                         wx.wxDefaultPosition, wx.wxSize(1000, 700))

-- Create main panel
local panel = wx.wxPanel(frame, wx.wxID_ANY)
local mainSizer = wx.wxBoxSizer(wx.wxVERTICAL)

-- Create plot widget
local plot = wxgnuplot.new(panel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(800, 500))
mainSizer:Add(plot:getPanel(), 1, wx.wxEXPAND + wx.wxALL, 5)

-- Create button panel
local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)

local btnBarChart = wx.wxButton(panel, wx.wxID_ANY, "Bar Chart")
local btnScatter = wx.wxButton(panel, wx.wxID_ANY, "Scatter Plot")
local btnMultiData = wx.wxButton(panel, wx.wxID_ANY, "Multiple Datasets")
local btnClear = wx.wxButton(panel, wx.wxID_ANY, "Clear")

buttonSizer:Add(btnBarChart, 0, wx.wxALL, 5)
buttonSizer:Add(btnScatter, 0, wx.wxALL, 5)
buttonSizer:Add(btnMultiData, 0, wx.wxALL, 5)
buttonSizer:Add(btnClear, 0, wx.wxALL, 5)

mainSizer:Add(buttonSizer, 0, wx.wxALIGN_CENTER)
panel:SetSizer(mainSizer)

-- Bar Chart with inline data
btnBarChart:Connect(wx.wxEVT_BUTTON, function(event)
    plot:clear()

    plot:cmd("set title 'Monthly Sales - Using Data Block'")
    plot:cmd("set xlabel 'Month'")
    plot:cmd("set ylabel 'Sales ($1000)'")
    plot:cmd("set style data histograms")
    plot:cmd("set style fill solid 0.8")
    plot:cmd("set boxwidth 0.7")
    plot:cmd("set grid ytics")
    plot:cmd("set yrange [0:*]")

    -- Create data block using set print (works with library API)
    plot:cmd("set print $SALES")
    plot:cmd('print "Jan 45"')
    plot:cmd('print "Feb 52"')
    plot:cmd('print "Mar 61"')
    plot:cmd('print "Apr 58"')
    plot:cmd('print "May 67"')
    plot:cmd('print "Jun 72"')
    plot:cmd('print "Jul 68"')
    plot:cmd('print "Aug 75"')
    plot:cmd('print "Sep 82"')
    plot:cmd('print "Oct 88"')
    plot:cmd('print "Nov 95"')
    plot:cmd('print "Dec 102"')
    plot:cmd("set print")  -- Close data block
    plot:cmd("plot $SALES using 2:xtic(1) title 'Monthly Sales' linecolor rgb '#4285F4'")

    plot:execute()
end)

-- Scatter plot with inline data
btnScatter:Connect(wx.wxEVT_BUTTON, function(event)
    plot:clear()

    plot:cmd("set title 'Temperature vs. Pressure - Data Block'")
    plot:cmd("set xlabel 'Temperature (°C)'")
    plot:cmd("set ylabel 'Pressure (kPa)'")
    plot:cmd("set grid")
    plot:cmd("set style line 1 lc rgb '#0060ad' pt 7 ps 1.5")

    -- Create data block using set print
    plot:cmd("set print $MEASUREMENTS")
    plot:cmd('print "20 101.3"')
    plot:cmd('print "25 105.2"')
    plot:cmd('print "30 110.8"')
    plot:cmd('print "35 118.5"')
    plot:cmd('print "40 127.3"')
    plot:cmd('print "45 138.2"')
    plot:cmd('print "50 151.5"')
    plot:cmd('print "55 166.8"')
    plot:cmd('print "60 184.5"')
    plot:cmd('print "65 205.2"')
    plot:cmd('print "70 229.1"')
    plot:cmd("set print")  -- Close data block
    plot:cmd("plot $MEASUREMENTS with points ls 1 title 'Measured Data'")

    plot:execute()
end)

-- Multiple datasets example
btnMultiData:Connect(wx.wxEVT_BUTTON, function(event)
    plot:clear()

    plot:cmd("set title 'Quarterly Sales Comparison'")
    plot:cmd("set xlabel 'Quarter'")
    plot:cmd("set ylabel 'Revenue ($M)'")
    plot:cmd("set style data linespoints")
    plot:cmd("set grid")
    plot:cmd("set key top left")

    -- Create first data block
    plot:cmd("set print $PRODUCT_A")
    plot:cmd('print "Q1 2.5"')
    plot:cmd('print "Q2 3.2"')
    plot:cmd('print "Q3 3.8"')
    plot:cmd('print "Q4 4.5"')
    plot:cmd("set print")

    -- Create second data block
    plot:cmd("set print $PRODUCT_B")
    plot:cmd('print "Q1 1.8"')
    plot:cmd('print "Q2 2.4"')
    plot:cmd('print "Q3 3.1"')
    plot:cmd('print "Q4 3.6"')
    plot:cmd("set print")

    -- Create third data block
    plot:cmd("set print $PRODUCT_C")
    plot:cmd('print "Q1 3.1"')
    plot:cmd('print "Q2 3.0"')
    plot:cmd('print "Q3 3.5"')
    plot:cmd('print "Q4 4.2"')
    plot:cmd("set print")

    -- Plot all three datasets
    plot:cmd("plot $PRODUCT_A using 2:xtic(1) with linespoints lw 2 pt 7 ps 1.5 title 'Product A', " ..
             "     $PRODUCT_B using 2:xtic(1) with linespoints lw 2 pt 5 ps 1.5 title 'Product B', " ..
             "     $PRODUCT_C using 2:xtic(1) with linespoints lw 2 pt 9 ps 1.5 title 'Product C'")

    plot:execute()
end)

-- Clear button
btnClear:Connect(wx.wxEVT_BUTTON, function(event)
    plot:clear()
    plot.bitmap = nil
    plot:refresh()
end)

-- Show initial bar chart
btnBarChart:Command(wx.wxCommandEvent(wx.wxEVT_BUTTON))

-- Show frame
frame:Show(true)

-- Start event loop
wx.wxGetApp():MainLoop()
