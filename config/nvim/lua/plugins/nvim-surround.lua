return {
    {
        "kylechui/nvim-surround",
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup {
                move_cursor = false,
            }
        end,
    },
}
