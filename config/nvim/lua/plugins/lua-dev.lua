return {
    {
        "rafcamlet/nvim-luapad",
        config = function()
            require("luapad").setup {
                wipe = false,
            }
        end,
    },
}
