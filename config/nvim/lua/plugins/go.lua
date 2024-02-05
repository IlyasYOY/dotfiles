return {
    {
        "ray-x/go.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-treesitter/nvim-treesitter",
            "ray-x/guihua.lua",
        },
        config = function()
            require("go").setup()
            vim.keymap.set("n", "<leader>gtf", "<CMD>GoTestFile<CR>")
        end,
        event = { "CmdlineEnter" },
        ft = { "go", "gomod" },
        build = ':lua require("go.install").update_all_sync()',
    },
}
