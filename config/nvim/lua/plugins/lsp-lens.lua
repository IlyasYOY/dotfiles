return {
    {
        "VidocqH/lsp-lens.nvim",
        lazy = true,
        cmd = {
            "LspLensOn",
            "LspLensOff",
            "LspLensToggle",
        },
        keys = {
            { "<leader>lls", "<cmd>LspLensToggle<CR>", desc = "Lsp Lens" },
        },
        config = function()
            require("lsp-lens").setup {
                enable = true,
            }
        end,
    },
}
