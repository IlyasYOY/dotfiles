vim.cmd [[ colorscheme ilyasyoy-monochrome ]]

vim.schedule(function()
    require("colorizer").setup()
end)

require("auto-dark-mode").setup {
    dark_mode_colorscheme = "ilyasyoy-monochrome",
    light_mode_colorscheme = "ilyasyoy-monochrome",
}
