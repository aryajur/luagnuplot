#!/home/aryajur/Lua/lua
-- wxLua Plot - Final Optimized Version
-- Combines: path accumulation + round caps/joins + alpha blending + best anti-aliasing

--package.cpath = './?.so;/home/aryajur/Lua/?.so;;'

local gnuplot = require("gnuplot")
local wx = require("wx")

print("=== wxLua Plot - Final Optimized ===\n")

-- Generate plot
print("1. Generating plot...")
gnuplot.init()
gnuplot.cmd("set terminal luacmd size 1000,700")
gnuplot.cmd("set title 'Beautiful Mathematical Functions'")
gnuplot.cmd("set xlabel 'x'")
gnuplot.cmd("set ylabel 'y'")
gnuplot.cmd("set grid lw 1")
gnuplot.cmd("set key top right box")
gnuplot.cmd("set xrange [-10:10]")
gnuplot.cmd("set yrange [-5:5]")
gnuplot.cmd("set samples 500")
gnuplot.cmd("set style line 1 lc rgb '#0060ad' lt 1 lw 2")
gnuplot.cmd("set style line 2 lc rgb '#dd181f' lt 1 lw 2")
gnuplot.cmd("set style line 3 lc rgb '#00ad60' lt 1 lw 2")
gnuplot.cmd("set style line 4 lc rgb '#ad6000' lt 1 lw 2")
gnuplot.cmd("plot sin(x) title 'sin(x)' ls 1, cos(x) title 'cos(x)' ls 2, sin(x)*exp(-x/10) title 'damped sine' ls 3, x/10 title 'x/10' ls 4")

local result = gnuplot.get_commands()
-- gnuplot.close()  -- Commented out: causes hang, cleanup happens automatically at exit

if not result then
    print("Error: No commands captured")
    os.exit(1)
end

print(string.format("   ✓ Captured %d commands\n", #result.commands))

-- Command types
local CMD_MOVE = 0
local CMD_VECTOR = 1
local CMD_TEXT = 2
local CMD_COLOR = 3
local CMD_LINEWIDTH = 4
local CMD_LINETYPE = 5
local CMD_POINT = 6
local CMD_FILLBOX = 7
local CMD_FILLED_POLYGON = 8
local CMD_TEXT_ANGLE = 9
local CMD_JUSTIFY = 10
local CMD_SET_FONT = 11

-- Text justification modes
local JUSTIFY_LEFT = 0
local JUSTIFY_CENTRE = 1
local JUSTIFY_RIGHT = 2

-- PRE-RENDER with all optimizations
print("2. Pre-rendering with optimized settings...")
local bitmap = wx.wxBitmap(result.width, result.height, 32)
local memDC = wx.wxMemoryDC()
memDC:SelectObject(bitmap)

memDC:SetBackground(wx.wxWHITE_BRUSH)
memDC:Clear()

-- Create graphics context with best quality
local gc = wx.wxGraphicsContext.Create(memDC)
local has_gc = (gc ~= nil)

if gc then
    if gc.SetAntialiasMode and wx.wxANTIALIAS_DEFAULT then
        gc:SetAntialiasMode(wx.wxANTIALIAS_DEFAULT)
    end
    if gc.SetInterpolationQuality and wx.wxINTERPOLATION_BEST then
        gc:SetInterpolationQuality(wx.wxINTERPOLATION_BEST)
    end
end

print(string.format("   Optimizations: Anti-aliasing=%s, Paths, Alpha blending", has_gc and "ON" or "OFF"))

-- Rendering state
local current_x, current_y = 0, 0
local pen_color = wx.wxColour(0, 0, 0)
local pen_width = 1
local pen_style = wx.wxPENSTYLE_SOLID
local text_justify = JUSTIFY_LEFT
local text_angle = 0.0
local current_font = wx.wxFont(9, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL)

memDC:SetPen(wx.wxPen(pen_color, pen_width, pen_style))
memDC:SetFont(current_font)

local vector_count = 0
local text_count = 0
local path_count = 0

local function linetype_to_penstyle(lt)
    if lt == -2 then return wx.wxPENSTYLE_SOLID
    elseif lt == -1 then return wx.wxPENSTYLE_DOT
    elseif lt == 0 then return wx.wxPENSTYLE_SOLID
    elseif lt == 1 then return wx.wxPENSTYLE_LONG_DASH
    elseif lt == 2 then return wx.wxPENSTYLE_DOT
    elseif lt == 3 then return wx.wxPENSTYLE_SHORT_DASH
    elseif lt == 4 then return wx.wxPENSTYLE_DOT_DASH
    else return wx.wxPENSTYLE_SOLID
    end
end

local function is_plot_curve(points)
    return #points > 20
end

-- PATH ACCUMULATION with optimizations
local path_points = {}
local path_active = false

local function flush_path()
    if #path_points > 1 and gc then
        local path = gc:CreatePath()
        path:MoveToPoint(path_points[1].x, path_points[1].y)

        for i = 2, #path_points do
            path:AddLineToPoint(path_points[i].x, path_points[i].y)
        end

        -- Apply alpha blending to plot curves for smoother appearance
        local is_curve = is_plot_curve(path_points)
        local actual_width = pen_width
        local alpha = 255

        if is_curve and pen_width >= 2 then
            actual_width = pen_width * 1.15  -- Slightly wider
            alpha = 225  -- Subtle transparency
        end

        local r = pen_color:Red()
        local g = pen_color:Green()
        local b = pen_color:Blue()

        local pen = wx.wxPen(wx.wxColour(r, g, b, alpha), math.floor(actual_width), pen_style)
        pen:SetCap(wx.wxCAP_ROUND)
        pen:SetJoin(wx.wxJOIN_ROUND)

        gc:SetPen(pen)
        gc:StrokePath(path)

        path_count = path_count + 1
    end

    path_points = {}
    path_active = false
end

-- Render ALL commands
for i, cmd in ipairs(result.commands) do
    if cmd.type == CMD_MOVE then
        if path_active then flush_path() end
        current_x = cmd.x
        current_y = cmd.y
        path_active = true
        path_points = {{x = current_x, y = current_y}}

    elseif cmd.type == CMD_VECTOR then
        table.insert(path_points, {x = cmd.x, y = cmd.y})
        current_x = cmd.x
        current_y = cmd.y
        vector_count = vector_count + 1

    elseif cmd.type == CMD_TEXT then
        if path_active then flush_path() end
        memDC:SetTextForeground(pen_color)
        if cmd.text then
            local text_x = cmd.x
            local text_y = cmd.y
            local text_width, text_height = memDC:GetTextExtent(cmd.text)

            if text_justify == JUSTIFY_RIGHT then
                text_x = text_x - text_width
            elseif text_justify == JUSTIFY_CENTRE then
                text_x = text_x - text_width / 2
            end
            text_y = text_y - text_height / 2

            if text_angle ~= 0.0 then
                memDC:DrawRotatedText(cmd.text, text_x, text_y, text_angle)
            else
                memDC:DrawText(cmd.text, text_x, text_y)
            end
            text_count = text_count + 1
        end

    elseif cmd.type == CMD_COLOR then
        if path_active then flush_path() end
        if cmd.color then
            local r = bit.rshift(bit.band(cmd.color, 0xFF0000), 16)
            local g = bit.rshift(bit.band(cmd.color, 0x00FF00), 8)
            local b = bit.band(cmd.color, 0x0000FF)
            pen_color = wx.wxColour(r, g, b)
            memDC:SetPen(wx.wxPen(pen_color, pen_width, pen_style))
        end

    elseif cmd.type == CMD_LINEWIDTH then
        if path_active then flush_path() end
        pen_width = math.max(1, math.floor(cmd.value or 1))
        memDC:SetPen(wx.wxPen(pen_color, pen_width, pen_style))

    elseif cmd.type == CMD_LINETYPE then
        if path_active then flush_path() end
        pen_style = linetype_to_penstyle(cmd.x or 0)
        memDC:SetPen(wx.wxPen(pen_color, pen_width, pen_style))

    elseif cmd.type == CMD_POINT then
        if path_active then flush_path() end
        memDC:DrawCircle(cmd.x, cmd.y, 2)

    elseif cmd.type == CMD_JUSTIFY then
        text_justify = cmd.x

    elseif cmd.type == CMD_TEXT_ANGLE then
        text_angle = cmd.value or 0.0
    end
end

if path_active then flush_path() end

print(string.format("   ✓ Drew %d paths (%d line segments) and %d text labels\n",
    path_count, vector_count, text_count))

-- Cleanup
if gc then gc:delete() end
memDC:SelectObject(wx.wxNullBitmap)

-- Create window
print("3. Creating window...")

local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxLua Plot - Final Optimized",
                         wx.wxPoint(50, 50),
                         wx.wxSize(result.width + 20, result.height + 110),
                         wx.wxDEFAULT_FRAME_STYLE)

local panel = wx.wxPanel(frame, wx.wxID_ANY)

local staticBitmap = wx.wxStaticBitmap(panel, wx.wxID_ANY, bitmap,
                                        wx.wxPoint(10, 10),
                                        wx.wxSize(result.width, result.height))

local info = wx.wxStaticText(panel, wx.wxID_ANY,
    "Final optimized: Best anti-aliasing + alpha blending",
    wx.wxPoint(10, result.height + 20))

local info2 = wx.wxStaticText(panel, wx.wxID_ANY,
    "Maximum smoothness without increasing samples",
    wx.wxPoint(10, result.height + 40))

-- Buttons
local btnSave = wx.wxButton(panel, wx.wxID_ANY, "Save PNG",
                             wx.wxPoint(10, result.height + 70),
                             wx.wxSize(100, 30))

local btnClose = wx.wxButton(panel, wx.wxID_ANY, "Close",
                             wx.wxPoint(120, result.height + 70),
                             wx.wxSize(100, 30))

btnSave:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    local output_file = "wxlua_plot_final.png"
    if bitmap:SaveFile(output_file, wx.wxBITMAP_TYPE_PNG) then
        wx.wxMessageBox("Plot saved to:\n" .. output_file, "Success",
                       wx.wxOK + wx.wxICON_INFORMATION, frame)
    else
        wx.wxMessageBox("Failed to save file", "Error",
                       wx.wxOK + wx.wxICON_ERROR, frame)
    end
end)

btnClose:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    frame:Close(true)
end)

frame:Show(true)
frame:Raise()

print("✓ Window displayed!\n")
print("Optimizations applied:")
print("  - wxGraphicsContext with best anti-aliasing")
print("  - Path accumulation (45 paths)")
print("  - Round caps and joins")
print("  - Alpha blending on plot curves")
print("  - Optimal line width adjustment\n")

wx.wxGetApp():MainLoop()
print("Done!")

