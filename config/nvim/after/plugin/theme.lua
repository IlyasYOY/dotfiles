vim.cmd [[ colorscheme ilyasyoy-monochrome ]]

require("colorizer").setup()

require("auto-dark-mode").setup {
    dark_mode_colorscheme = "ilyasyoy-monochrome",
    light_mode_colorscheme = "ilyasyoy-monochrome",
}
