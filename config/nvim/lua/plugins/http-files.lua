return {
    {
        "vhyrro/luarocks.nvim",
        priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
        config = true,
    },
    {
        "rest-nvim/rest.nvim",
        ft = "http",
        dependencies = { "luarocks.nvim" },
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
