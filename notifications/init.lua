--------------------------------------------------------------------------------
-- @author dodo
-- @copyright 2011 https://github.com/dodo
-- @release v3.4-503-g4972a28
--------------------------------------------------------------------------------

local wibox = require("wibox")
local menu = require("uzful.menu.popup")
local naughty = require("naughty")
local vicious = require("vicious")
local beautiful = require("beautiful")
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local table = table
local widgets = {}

local print = print
module("uzful.notifications")


data = {}

function patch()
    local notify = naughty.notify
    naughty.notify = function (args)
        notify(args)
        update(args)
    end
end


function update(args)
    args = args or {}
    local preset = args.preset or naughty.config.default_preset or {}
    local icon = args.icon or preset.icon
    local text = args.text or preset.text or ""
    local screen = args.screen or preset.screen or 1
    local theme = beautiful.get()
    local color = {
        fg_normal = args.fg or preset.fg or theme.fg_normal or '#ffffff',
        bg_normal = args.bg or preset.bg or theme.bg_normal or '#535d6c',
        border_color = args.border_color or preset.border_color or
                       theme.bg_focus or '#535d6c',
    }
    table.insert(data, {
        screen = screen,
        color = color,
        text = text,
        icon = icon })

    local updates = {}
    for wid, conf in pairs(widgets) do
        if conf.screen == screen then
            updates[wid] = wid
        end
    end
    for _,wid in pairs(updates) do wid:add({text=text,theme=color,icon=icon})end
end


function add(wid, args)
    local conf = widgets[wid]
    if conf == nil or not conf.visible then return end
    wid.number = wid.number + 1
    conf.counter = conf.counter + 1
    wid.text:set_markup(vicious.helpers.format(conf.format, { wid.number }))
    local item = wid.menu:add({
        theme = args.theme or {},
        args.text or "", function ()  end, args.icon },
        conf.counter)
end


function show(wid, args)
    local conf = widgets[wid]
    if conf == nil then return end
    if conf.visible then
        conf.menu_visible = true
        wid.menu:show(args)
    end
end


function hide(wid)
    local conf = widgets[wid]
    if conf == nil then return end
    if conf.visible then
        conf.menu_visible = false
        wid.menu:hide()
    end
end


function toggle_menu(wid, args)
    local conf = widgets[wid]
    if conf == nil then return end
    if conf.visible then
        conf.menu_visible = not conf.menu_visible
        wid.menu:toggle(args)
    end
end


function enable(wid)
    local conf = widgets[wid]
    if conf == nil or conf.visible then return end
    conf.visible = true
    wid.text:set_markup(vicious.helpers.format(conf.format, { wid.number }))
    naughty.suspend()
end


function disable(wid)
    local conf = widgets[wid]
    if conf == nil or not conf.visible then return end
    local new = {}
    for _, v in pairs(data) do
        if v.screen ~= conf.screen then
            table.insert(new, v)
        end
    end
    wid:hide()
    data = new
    wid.number = 0
    conf.visible = false
    wid.text:set_markup(conf.disabled)
    naughty.resume()
end


function toggle(wid)
    local conf = widgets[wid]
    if conf == nil then return end
    if conf.visible then
        wid:disable()
    else
        wid:enable()
    end
end


function new(screen, args)
    screen = screen or 1
    args = args or {}

    local conf = {
        disabled = vicious.helpers.format(args.disabled or "$1", { "⤫" }),
        format = args.text or "$1",
        counter = 0,
        menu = args.menu or {},
        menu_visible = false,
        visible = args.visible ~= nil and args.visible,
        screen = screen }

    local ret = {
        menu = menu(),
        text = wibox.widget.textbox(),
        toggle_menu = toggle_menu,
        disable = disable,
        enable = enable,
        toggle = toggle,
        number = 0,
        show = show,
        hide = hide,
        add = add }
    widgets[ret] = conf


    for _, v in pairs(data) do
        if v.screen == screen then
            ret:add({ text = v.text, theme = v.color, icon = v.icon })
        end
    end

    conf.visible = not conf.visible
    ret:toggle()

    return ret
end


setmetatable(_M, { __call = function (_, ...) return new(...) end })
