return {
    {
        "vim-test/vim-test",
        lazy = true,
        ft = { "java" },
        config = function()
            vim.keymap.set(
                "n",
                "<leader>tt",
                "<cmd>TestFile<cr>",
                { silent = true }
            )

            vim.keymap.set(
                "n",
                "<leader>ta",
                "<cmd>TestSuite<cr>",
                { silent = true }
            )
        end,
    },
}
