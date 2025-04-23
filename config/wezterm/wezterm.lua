local wezterm = require "wezterm"

local config = {}

config.font = wezterm.font "GoMono Nerd Font"
config.font_size = 18
-- config.color_scheme = "alacritty"
config.color_scheme = "Bamboo"
config.colors = {
    background = "#000000",
    foreground = "#bcbcbc",
}

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

return config
