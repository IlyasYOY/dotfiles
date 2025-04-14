return {
    "epwalsh/obsidian.nvim",
    version = "*",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    lazy = true,
    ft = "markdown",
    config = function()
        require("obsidian").setup {
            workspaces = {
                {
                    name = "personal",
                    path = "~/vimwiki",
                },
            },

            daily_notes = {
                folder = "diary",
                date_format = "%Y-%m-%d",
                template = "daily",
            },
            ui = {
                enable = false,
            },
            disable_frontmatter = true,
            templates = {
                folder = "meta/templates",
            },
            picker = {
                name = "fzf-lua",
            },
        }

        vim.keymap.set("n", "<leader>nn", "<cmd>ObsidianFollowLink<cr>")
        vim.keymap.set("n", "<leader>nN", "<cmd>ObsidianNew<cr>")
        vim.keymap.set("n", "<leader>no", "<cmd>ObsidianOpen<cr>")
        vim.keymap.set("n", "<leader>nd", "<cmd>ObsidianDailies<cr>")
        vim.keymap.set("n", "<leader>nrn", "<cmd>ObsidianRename<cr>")
        vim.keymap.set("n", "<leader>nT", "<cmd>ObsidianTemplate<cr>")
        vim.keymap.set("n", "<leader>nb", "<cmd>ObsidianBacklinks<cr>")
        vim.keymap.set("n", "<leader>nfg", "<cmd>ObsidianSearch<cr>")

        -- TODO: Implement
        -- vim.keymap.set("n", "<leader>nff", "<cmd>ObsNvimFindNote<cr>")
        -- vim.keymap.set("n", "<leader>nfj", "<cmd>ObsNvimFindInJournal<cr>")
        -- vim.keymap.set("n", "<leader>nM", "<cmd>ObsNvimMove<cr>")
        -- vim.keymap.set("n", "<leader>nw", "<cmd>ObsNvimWeeklyNote<cr>")
        -- vim.keymap.set("n", "<leader>nr", "<cmd>ObsNvimRandomNote<cr>")
        -- vim.keymap.set(
        --     "n",
        --     "<leader>ny",
        --     "<cmd>ObsNvimCopyObsidianLinkToNote<cr>"
        -- )
    end,
}
