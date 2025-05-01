return {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    config = function()
        require("obsidian").setup {
            workspaces = {
                {
                    name = "personal",
                    path = "~/vimwiki",
                },
            },
            disable_frontmatter = true,
            new_notes_location = "notes_subdir",
            note_id_func = function(title)
                local prefix = tostring(os.date("%Y-%m-%d", os.time()))
                if title ~= nil then
                    title = title
                        :gsub(" ", "-")
                        :gsub("[^A-Za-z0-9-]", "")
                        :lower()
                else
                    title = os.time()
                end
                return prefix .. "-" .. title
            end,
            daily_notes = {
                folder = "diary",
                date_format = "%Y-%m-%d",
                template = "daily",
            },
            ui = {
                enable = false,
            },
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
