return {
    {
        "IlyasYOY/obs.nvim",
        dependencies = {
            "IlyasYOY/coredor.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
        },
        dev = true,
        config = function()
            local obs = require "obs"

            obs.setup {
                vault_home = "~/vimwiki",
                journal = {
                    template_name = "daily",
                },
            }

            vim.keymap.set("n", "<leader>nn", function()
                obs.vault:run_if_note(function()
                    obs.vault:follow_link()
                end)
            end, { desc = "navigate to note" })

            vim.keymap.set("n", "<leader>nN", function()
                local input = vim.fn.input {
                    prompt = "New note name: ",
                    default = "",
                }
                local file = obs.vault:create_note(input)
                if file then
                    file:edit()
                else
                    vim.notify("Note '" .. input .. "' already exists")
                end
            end, { desc = "create new note" })

            vim.keymap.set("n", "<leader>nd", function()
                obs.vault:open_daily()
            end, { desc = "notes daily" })

            vim.keymap.set("n", "<leader>nrn", function()
                obs.vault:rename_current_note()
            end, { desc = "notes rename current" })

            vim.keymap.set("n", "<leader>nT", function()
                obs.vault:run_if_note(function()
                    obs.vault:find_and_insert_template()
                end)
            end, { desc = "Inserts notes Template" })

            vim.keymap.set("n", "<leader>nM", function()
                obs.vault:run_if_note(function()
                    obs.vault:find_directory_and_move_current_note()
                end)
            end, { desc = "move notes to directory" })

            vim.keymap.set("n", "<leader>nb", function()
                obs.vault:run_if_note(function()
                    obs.vault:find_current_note_backlinks()
                end)
            end, { desc = "notes find backlinks" })

            -- Find stuff

            vim.keymap.set("n", "<leader>nfj", function()
                obs.vault:find_journal()
            end, { desc = "notes find journal" })

            vim.keymap.set("n", "<leader>nff", function()
                obs.vault:find_note()
            end, { desc = "notes files find" })

            vim.keymap.set("n", "<leader>nfg", function()
                obs.vault:grep_note()
            end, { desc = "notes files grep" })
        end,
    },
}
