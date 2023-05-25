return {
    {
        "rest-nvim/rest.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        lazy = true,
        keys = {
            "<leader><leader>R",
            "<leader><leader>r",
            "<leader><leader>Rr",
        },
        config = function()
            require("rest-nvim").setup()

            vim.keymap.set("n", "<leader><leader>R", "<Plug>RestNvim", {
                desc = "runs http request",
            })
            vim.keymap.set("n", "<leader><leader>r", "<Plug>RestNvimPreview", {
                desc = "preview request to be run",
            })
            vim.keymap.set("n", "<leader><leader>Rr", "<Plug>RestNvimLast", {
                desc = "re-run last request",
            })
        end,
    },
}
