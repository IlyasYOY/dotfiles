return {
    {
        "mbbill/undotree",
        lazy = true,
        keys = {
            "<leader>ut",
        },
        cmd = {
            "UndotreeToggle",
        },
        config = function()
            vim.keymap.set("n", "<leader>ut", ":UndotreeToggle<CR>")
        end,
    },
}
