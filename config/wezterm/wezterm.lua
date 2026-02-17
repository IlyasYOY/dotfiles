local wezterm = require "wezterm"

local config = {}

-- here i have multiple fonts simply to be able to change them at the speed of
-- thought.
config.font = wezterm.font "0xProto Nerd Font"
config.font = wezterm.font "Atkinson Hyperlegible Mono"
config.font = wezterm.font "GoMono Nerd Font"

config.font_size = 18

local schemes = {
  ['IlyasYOY Monochrome Dark'] = {
    foreground = '#dadada',
    background = '#000000',
    cursor_bg = '#8787af',
    cursor_border = '#dadada',
    selection_bg = '#303030',
    selection_fg = '#dadada',
    ansi = {
      '#303030',
      '#722529',
      '#416241',
      '#ffaf00',
      '#00afff',
      '#ff005f',
      '#00afaf',
      '#dadada',
    },
    brights = {
      '#707070',
      '#da8d8d',
      '#8dda9e',
      '#ffaf00',
      '#00afff',
      '#ff005f',
      '#00afaf',
      '#ffffff',
    },
    scrollbar_thumb = '#303030',
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
    ansi = {
      '#e4e4e4',
      '#da8d8d',
      '#8dda9e',
      '#ffaf00',
      '#00afff',
      '#ff005f',
      '#00afaf',
      '#000000',
    },
    brights = {
      '#626262',
      '#da8d8d',
      '#8dda9e',
      '#ffaf00',
      '#00afff',
      '#ff005f',
      '#00afaf',
      '#ffffff',
    },
    scrollbar_thumb = '#e4e4e4',
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

for name, scheme in pairs(schemes) do
  config.color_schemes = schemes
end

local function scheme_for_appearance(appearance)
    if appearance:find 'Dark' then
        return 'IlyasYOY Monochrome Dark'
    else
        return 'IlyasYOY Monochrome Light'
    end
end

wezterm.on('window-config-reloaded', function(window, pane)
    local overrides = window:get_config_overrides() or {}
    local appearance = window:get_appearance()
    local scheme = scheme_for_appearance(appearance)

    if overrides.color_scheme ~= scheme then
        overrides.color_scheme = scheme
        window:set_config_overrides(overrides)
    end
end)

config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

return config
