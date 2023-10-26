return {
    {
        "sindrets/diffview.nvim",
        lazy = true,
        cmd = {
            "DiffviewOpen",
        },
        keys = {
            "<leader>gdo",
            "<leader>gdO",
            "<leader>gdc",
        },
        config = function()
            vim.keymap.set("n", "<leader>gdo", ":DiffviewOpen origin<CR>")
            vim.keymap.set("n", "<leader>gdO", ":DiffviewOpen<CR>")
            vim.keymap.set("n", "<leader>gdc", ":DiffviewClose<CR>")
        end,
    },
}
