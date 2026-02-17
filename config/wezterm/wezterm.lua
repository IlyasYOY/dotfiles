local wezterm = require "wezterm"

local M = {}

M.font_size = 18
M.font = wezterm.font "GoMono Nerd Font"

    M.color_schemes = {
        ['IlyasYOY Monochrome Dark'] = {
            foreground = '#dadada',
            background = '#000000',
            cursor_bg = '#8787af',
            cursor_border = '#dadada',
            selection_bg = '#303030',
            selection_fg = '#dadada',
            scrollbar_thumb = '#303030',
            ansi = {
                '#191919', -- black (noise)
                '#ff005f', -- red (error)
                '#416241', -- green (add)
                '#ffaf00', -- yellow (visual)
                '#00afff', -- blue (search)
                '#d787d7', -- magenta (diff/dotted accents)
                '#00afaf', -- cyan
                '#dadada', -- white (fg)
            },
            brights = {
                '#707070', -- bright black (muted)
                '#ff87af', -- bright red
                '#8dda9e', -- bright green
                '#ffd080', -- bright yellow
                '#87afd7', -- bright blue
                '#ffd7ff', -- bright magenta
                '#87d7d7', -- bright cyan
                '#ffffff', -- bright white
            },
            tab_bar = {
                background = '#000000',
                active_tab = { bg_color = '#1c1c1c', fg_color = '#000000', intensity = 'Bold' },
                inactive_tab = { bg_color = '#000000', fg_color = '#707070' },
                inactive_tab_hover = { bg_color = '#303030', fg_color = '#dadada' },
                new_tab = { bg_color = '#000000', fg_color = '#707070' },
                new_tab_hover = { bg_color = '#303030', fg_color = '#dadada' },
            },
        },
        ['IlyasYOY Monochrome Light'] = {
            foreground = '#000000',
            background = '#d7d7d7',
            cursor_bg = '#8787af',
            cursor_border = '#000000',
            selection_bg = '#e4e4e4',
            selection_fg = '#000000',
            scrollbar_thumb = '#e4e4e4',
            ansi = {
                '#626262', -- black (muted)
                '#da8d8d', -- red (remove)
                '#8dda9e', -- green (add)
                '#ffaf00', -- yellow (visual)
                '#00afff', -- blue (search)
                '#d787d7', -- magenta
                '#00afaf', -- cyan
                '#000000', -- white (fg)
            },
            brights = {
                '#cccccc', -- bright black (noise)
                '#ff005f', -- bright red (error)
                '#416241', -- bright green
                '#ffd080', -- bright yellow
                '#87afd7', -- bright blue
                '#ffd7ff', -- bright magenta
                '#87d7d7', -- bright cyan
                '#1c1c1c', -- bright white (elevated)
            },
            tab_bar = {
                background = '#d7d7d7',
                active_tab = { bg_color = '#eeeeee', fg_color = '#d7d7d7', intensity = 'Bold' },
                inactive_tab = { bg_color = '#d7d7d7', fg_color = '#626262' },
                inactive_tab_hover = { bg_color = '#e4e4e4', fg_color = '#000000' },
                new_tab = { bg_color = '#d7d7d7', fg_color = '#626262' },
                new_tab_hover = { bg_color = '#e4e4e4', fg_color = '#000000' },
            },
        },
    }

local function scheme_for_appearance(appearance)
    if appearance:find 'Dark' then
        return 'IlyasYOY Monochrome Dark'
    else
        return 'IlyasYOY Monochrome Light'
    end
end

wezterm.on('window-config-reloaded', function(window, _)
    local overrides = window:get_config_overrides() or {}
    local appearance = window:get_appearance()
    local scheme = scheme_for_appearance(appearance)

    if overrides.color_scheme ~= scheme then
        overrides.color_scheme = scheme
        window:set_config_overrides(overrides)
    end
end)

M.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

M.hide_tab_bar_if_only_one_tab = true
M.window_decorations = "RESIZE"

M.send_composed_key_when_left_alt_is_pressed = false
M.send_composed_key_when_right_alt_is_pressed = false

return M
