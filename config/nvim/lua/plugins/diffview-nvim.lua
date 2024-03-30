return {
    {
        "sindrets/diffview.nvim",
        lazy = true,
        cmd = {
            "DiffviewOpen",
            "DiffviewLog",
            "DiffviewFileHistory",
        },
        keys = {
            "<leader>gdo",
            "<leader>gdO",
            "<leader>gdc",
        },
        config = function()
            vim.keymap.set("n", "<leader>gdO", ":DiffviewOpen origin<CR>")
            vim.keymap.set("n", "<leader>gdo", ":DiffviewOpen<CR>")
            vim.keymap.set("n", "<leader>gdc", ":DiffviewClose<CR>")
        end,
    },
}
