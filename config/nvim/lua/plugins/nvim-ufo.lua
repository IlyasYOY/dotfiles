return {
    {
        "kevinhwang91/nvim-ufo",
        dependencies = {
            "kevinhwang91/promise-async",
            "nvim-treesitter/nvim-treesitter",
        },
        cond = false,
        lazy = true,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("ufo").setup {
                provider_selector = function(bufnr, filetype, buftype)
                    return { "treesitter", "indent" }
                end,
            }

            vim.o.foldcolumn = "1"
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true

            vim.keymap.set("n", "zR", require("ufo").openAllFolds)
            vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
        end,
    },
}
