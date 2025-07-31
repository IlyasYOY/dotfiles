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
                    path = "~/Projects/IlyasYOY/notes-wiki",
                },
            },
            legacy_commands = false,
            disable_frontmatter = true,
            new_notes_location = "notes_subdir",
            note_id_func = function(title)
                local prefix = tostring(os.date("%Y-%m-%d", os.time()))
                if title ~= nil then
                    title =
                        title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
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

        vim.keymap.set("n", "<leader>nn", "<cmd>Obsidian follow_link<cr>")
        vim.keymap.set("n", "<leader>nN", "<cmd>Obsidian new<cr>")
        vim.keymap.set("n", "<leader>no", "<cmd>Obsidian open<cr>")
        vim.keymap.set("n", "<leader>nd", "<cmd>Obsidian dailies<cr>")
        vim.keymap.set("n", "<leader>nrn", "<cmd>Obsidian rename<cr>")
        vim.keymap.set("n", "<leader>nT", "<cmd>Obsidiant template<cr>")
        vim.keymap.set("n", "<leader>nb", "<cmd>Obsidian backlinks<cr>")
        vim.keymap.set("n", "<leader>nfg", "<cmd>Obsidian search<cr>")

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
