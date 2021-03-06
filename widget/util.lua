--------------------------------------------------------------------------------
-- @author dodo
-- @copyright 2011 https://github.com/dodo
-- @release v3.4-503-g4972a28
--------------------------------------------------------------------------------

local util = require("uzful.util")
local Wibox = require("wibox")
local setmetatable = setmetatable
local pairs = pairs
local type = type
local capi = { screen = screen }

module("uzful.widget.util")


--- wibox helper
-- Just a wrapper for a nicer interface for `wibox`
-- @param args any wibox args plus screen, visible and widget
-- @param args.screen when given `wibox.screen` will be set
-- @param args.visible when given `wibox.visible` will be set
-- @param args.widget when given `wibox:set_widget` will be invoked
-- @return wibox object
function wibox(args)
    local w = Wibox(args)
    w.screen = args.screen or 1
    w.visible = args.visible or false
    if args.widget then
        w:set_widget(args.widget)
    end
    return w
end

--- widget property setter
-- Any given property will invoke `widget:set_[property_key]([property_value])`.
-- @param widget the widget to be filled with properties
-- @param properties a table with the properties
-- @return the given widget
function set_properties(widget, properties)
    local fun = nil
    for name, property in pairs(properties) do
        fun = widget["set_" .. name]
        if fun then
            fun(widget, property)
        end
    end
    return widget
end

--- wibox presettings for an infobox
-- type = notification
-- visible = false
-- ontop = true
-- @param args any wibox args like in uzful.widget.util.wibox
-- @return wibox object
function infobox(args)
    local box = wibox(util.table.update({ type = "notification",
        visible = false, ontop = true }, args))
    local ret = {}
    local size = args.size
    local align = args.align or "left"
    local position = args.position or "top"

    ret.update = function ()
        local screen = screen or box.screen or 1
        local area = capi.screen[screen].workarea

        if size and type(size) == "function" then
            box.width, box.height = size()
        end

        if position == "top" then
            box.y = area.y
        elseif position == "center" then
            box.y = area.y + (area.height - box.height) * 0.5
        elseif position == "bottom" then
            box.y = area.y + area.height - box.height
        end

        if align == "left" then
            box.x = area.x
        elseif align == "center" then
            box.x = area.x + (area.width - box.width) * 0.5
        elseif align == "right" then
            box.x = area.x + area.width - box.width
        end
    end
    ret.toggle = function ()
        if not box.visible then
            box.screen = args.screen or box.screen
        end
        box.visible = not box.visible
    end
    ret.hide = function ()
        if box.visible then
            box.visible = false
        end
    end
    ret.show = function ()
        if not box.visible then
            box.screen = args.screen or box.screen
            box.visible = true
        end
    end
    ret.set_align = function (m, mode)
        mode = mode or m
        local allowed = { left = true, center = true, right = true }
        if allowed[mode] then
            align = mode
            ret:update()
        end
    end
    ret.set_position = function (m, mode)
        mode = mode or m
        local allowed = { top = true, center = true, bottom = true }
        if allowed[mode] then
            position = mode
            ret:update()
        end
    end

    setmetatable(ret, {
        __index = box,
        __newindex = box
    })
    ret:update()
    return ret
end
