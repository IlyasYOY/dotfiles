return {
    {
        "vim-test/vim-test",
        lazy = true,
        keys = {
            "<leader>t",
            "<leader>T",
        },
        config = function()
            vim.keymap.set(
                "n",
                "<leader>t",
                "<cmd>TestFile<cr>",
                { silent = true }
            )
            vim.keymap.set(
                "n",
                "<leader>T",
                "<cmd>TestSuite<cr>",
                { silent = true }
            )
        end,
    },
}
