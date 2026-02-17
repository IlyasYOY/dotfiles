return {
    {
        "github/copilot.vim",
        event = "VeryLazy",
        config = function()
            vim.g.copilot_filetypes = {
                ["*"] = false,

                lua = true,
                gitcommit = true,
                python = true,
                go = true,
                java = true,
                make = true,
                sh = true,
            }
        end
    }
}
