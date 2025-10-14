-- wxgnuplot.lua
-- Reusable gnuplot plotting widget for wxLua applications
--
-- Usage:
--   local wxgnuplot = require("wxgnuplot")
--   local plot = wxgnuplot.new(parent, id, pos, size)
--   sizer:Add(plot:getPanel(), 1, wx.wxEXPAND)
--   plot:cmd("set title 'My Plot'")
--   plot:cmd("plot sin(x)")
--   plot:execute()

local wxgnuplot = {}

-- Command type constants (from gnuplot terminal)
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

-- Convert gnuplot linetype to wxPen style
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

-- Check if path represents a plot curve (for optimization)
local function is_plot_curve(points)
    return #points > 20
end

-- Render gnuplot commands to a wxBitmap
-- Returns: wxBitmap or nil on error
local function render_commands(commands, width, height)
    if not commands or #commands == 0 then
        return nil
    end

    -- Create bitmap and device context
    local bitmap = wx.wxBitmap(width, height, 32)
    local memDC = wx.wxMemoryDC()
    memDC:SelectObject(bitmap)

    -- Clear background
    memDC:SetBackground(wx.wxWHITE_BRUSH)
    memDC:Clear()

    -- Create graphics context for anti-aliasing
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

    -- Path accumulation
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
        end

        path_points = {}
        path_active = false
    end

    -- Render all commands
    for i, cmd in ipairs(commands) do
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

        elseif cmd.type == CMD_FILLBOX then
            if path_active then flush_path() end
            -- Draw a filled rectangle
            -- cmd.x = x, cmd.y = y, cmd.x2 = width, cmd.y2 = height
            local brush = wx.wxBrush(pen_color, wx.wxBRUSHSTYLE_SOLID)
            memDC:SetBrush(brush)
            memDC:DrawRectangle(cmd.x, cmd.y, cmd.x2, cmd.y2)

        elseif cmd.type == CMD_JUSTIFY then
            text_justify = cmd.x

        elseif cmd.type == CMD_TEXT_ANGLE then
            text_angle = cmd.value or 0.0
        end
    end

    if path_active then flush_path() end

    -- Cleanup
    if gc then gc:delete() end
    memDC:SelectObject(wx.wxNullBitmap)

    return bitmap
end

-- Create a new plot widget
-- parent: wxWindow parent
-- id: window ID (or wx.wxID_ANY)
-- pos: wxPoint position (optional, defaults to wx.wxDefaultPosition)
-- size: wxSize size (optional, defaults to wx.wxSize(400, 300))
-- Returns: plot object
function wxgnuplot.new(parent, id, pos, size)
    local gnuplot = require("gnuplot")

    -- Default parameters
    id = id or wx.wxID_ANY
    pos = pos or wx.wxDefaultPosition
    size = size or wx.wxSize(400, 300)

    -- Create plot object
    local plot = {
        panel = nil,
        bitmap = nil,
        commands = {},
        width = size:GetWidth(),
        height = size:GetHeight(),
        gnuplot = gnuplot,
        gnuplot_initialized = false
    }

    -- Create wxPanel
    plot.panel = wx.wxPanel(parent, id, pos, size)

    -- Paint event handler
    plot.panel:Connect(wx.wxEVT_PAINT, function(event)
        local dc = wx.wxPaintDC(plot.panel)
        if plot.bitmap and plot.bitmap:IsOk() then
            dc:DrawBitmap(plot.bitmap, 0, 0, false)
        end
        dc:delete()
    end)

    -- Resize event handler
    plot.panel:Connect(wx.wxEVT_SIZE, function(event)
        -- Get actual client size from the panel (not event size)
        local client_size = plot.panel:GetClientSize()
        local new_width = client_size:GetWidth()
        local new_height = client_size:GetHeight()

        --print(string.format("[RESIZE] Event fired: old=%dx%d, new=%dx%d",
              plot.width, plot.height, new_width, new_height))

        -- Only re-render if size is valid and has changed
        if new_width > 0 and new_height > 0 and
           (new_width ~= plot.width or new_height ~= plot.height) then
            plot.width = new_width
            plot.height = new_height

            -- Re-execute plot commands with new size
            if #plot.commands > 0 then
                --print("[RESIZE] Re-executing plot commands...")
                plot:execute()
                --print("[RESIZE] Plot re-rendered")
            else
                --print("[RESIZE] No commands to re-execute")
            end
        else
            --print("[RESIZE] Size unchanged or invalid, skipping re-render")
        end

        event:Skip()
    end)
--[=[
    -- Find top-level frame and add resize handler (needed for Linux)
    -- On Linux, panel resize events may not fire reliably, so we also
    -- monitor the parent frame's resize events
    local function find_top_frame(widget)
        local current = widget
        while current do
            local parent = current:GetParent()
            if not parent then
                -- Check if this is a frame
                if current:DynamicCast("wxFrame") then
                    return current
                end
                return nil
            end
            current = parent
        end
        return nil
    end

    local top_frame = find_top_frame(plot.panel)
    if top_frame then
        top_frame:Connect(wx.wxEVT_SIZE, function(event)
            -- Check if panel size has changed
            local client_size = plot.panel:GetClientSize()
            local new_width = client_size:GetWidth()
            local new_height = client_size:GetHeight()

            print(string.format("[FRAME RESIZE] Checking panel: old=%dx%d, new=%dx%d",
                  plot.width, plot.height, new_width, new_height))

            if new_width > 0 and new_height > 0 and
               (new_width ~= plot.width or new_height ~= plot.height) then
                plot.width = new_width
                plot.height = new_height

                if #plot.commands > 0 then
                    print("[FRAME RESIZE] Re-executing plot commands...")
                    plot:execute()
                    print("[FRAME RESIZE] Plot re-rendered")
                end
            end

            event:Skip()
        end)
        print("[wxgnuplot] Connected to frame resize events for cross-platform compatibility")
    end
]=]
    -- Method: Get the wxPanel (for adding to sizers)
    function plot:getPanel()
        return self.panel
    end

    -- Method: Add a gnuplot command to the stack
    function plot:cmd(command)
        table.insert(self.commands, command)
    end

    -- Method: Execute all stacked commands and render
    function plot:execute()
        if #self.commands == 0 then
            return false, "No commands to execute"
        end

        -- Initialize gnuplot if needed
        if not self.gnuplot_initialized then
            self.gnuplot.init()
            self.gnuplot_initialized = true
        end

        -- Process commands and inject terminal size setting before plot commands
        -- This ensures the plot is generated at the correct size
        for i, cmd in ipairs(self.commands) do
            -- Check if this is a plot command
            local cmd_lower = cmd:lower():match("^%s*(%S+)")
            if cmd_lower == "plot" or cmd_lower == "splot" or cmd_lower == "replot" then
                -- Set terminal right before plot command
                self.gnuplot.cmd(string.format("set terminal luacmd size %d,%d", self.width, self.height))
            end

            -- Execute the user command
            self.gnuplot.cmd(cmd)
        end

        -- Get rendering commands
        local result = self.gnuplot.get_commands()
        if not result or not result.commands then
            return false, "Failed to get gnuplot commands"
        end

        -- Render to bitmap at the size we requested
        self.bitmap = render_commands(result.commands, self.width, self.height)

        if not self.bitmap then
            return false, "Failed to render bitmap"
        end

        -- Refresh panel
        self.panel:Refresh()

        return true
    end

    -- Method: Clear command stack (keeps rendered plot)
    function plot:clear()
        self.commands = {}
    end

    -- Method: Force repaint
    function plot:refresh()
        self.panel:Refresh()
    end

    -- Method: Get current size
    function plot:getSize()
        return self.width, self.height
    end

    return plot
end

return wxgnuplot
