return {
    {
        "aaronhallaert/advanced-git-search.nvim",
        lazy = true,
        keys = {
            "<leader>fG",
        },
        config = function()
            require("telescope").load_extension "advanced_git_search"
            vim.keymap.set("n", "<leader>fG", "<cmd>AdvancedGitSearch<cr>")
        end,
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "tpope/vim-fugitive",
            "sindrets/diffview.nvim",
        },
    },
}
