return {
    { "IlyasYOY/theme.nvim" },
    {
        "norcalli/nvim-colorizer.lua",
        config = function()
            require("colorizer").setup()
        end,
    },
    {
        "f-person/auto-dark-mode.nvim",
        config = function()
            vim.cmd [[ colorscheme ilyasyoy-monochrome ]]
            require("auto-dark-mode").setup {
                dark_mode_colorscheme = "ilyasyoy-monochrome",
                light_mode_colorscheme = "ilyasyoy-monochrome",
            }
        end,
    },
}
