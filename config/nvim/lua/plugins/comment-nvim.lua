return {
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
    },
}
