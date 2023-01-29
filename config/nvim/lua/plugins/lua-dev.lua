return {
    "folke/neodev.nvim",
    {
        "rafcamlet/nvim-luapad",
        config = function()
            require("luapad").setup {
                wipe = false,
            }
        end,
    },
}
