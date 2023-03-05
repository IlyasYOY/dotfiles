return {
    {
        "IlyasYOY/obs.nvim",
        dependencies = {
            "IlyasYOY/coredor.nvim",
            "nvim-lua/plenary.nvim",
        },
        -- dev = true,
        config = function()
            local obs = require "obs"

            obs.setup {
                journal = {
                    template_name = "daily",
                },
            }

            vim.keymap.set("n", "<leader>nT", function()
                obs.vault:run_if_note(function()
                    obs.vault:find_and_insert_template()
                end)
            end, { desc = "Inserts [n]otes [T]emplate" })

            vim.keymap.set("n", "<leader>nn", function()
                obs.vault:run_if_note(function()
                    obs.vault:follow_link()
                end)
            end, { desc = "navigate to note" })

            vim.keymap.set("n", "<leader>nN", function()
                local input = vim.fn.input {
                    promt = "New note name: ",
                    default = "",
                }
                local file = obs.vault:create_note(input)
                if file then
                    file:edit()
                else
                    vim.notify("Note '" .. input .. "' already exists")
                end
            end, { desc = "create new note" })

            vim.keymap.set("n", "<leader>nfj", function()
                obs.vault:find_journal()
            end, { desc = "[n]otes [f]ind [j]ournal" })

            vim.keymap.set("n", "<leader>nd", function()
                obs.vault:open_daily()
            end, { desc = "[n]otes [d]aily" })

            vim.keymap.set("n", "<leader>nff", function()
                obs.vault:find_note()
            end, { desc = "[n]otes [f]iles [f]ind" })

            vim.keymap.set("n", "<leader>nfg", function()
                obs.vault:grep_note()
            end, { desc = "[n]otes [f]iles [g]rep" })

            vim.keymap.set("n", "<leader>nfb", function()
                obs.vault:run_if_note(function()
                    obs.vault:find_current_note_backlinks()
                end)
            end, { desc = "[n]otes [f]ind [b]acklinks" })

            vim.keymap.set("n", "<leader>nrn", function()
                obs.vault:rename_current_note()
            end, { desc = "[n]otes [r]e[n]ame current" })

            local group = vim.api.nvim_create_augroup(
                "IlyasyoyObsidian",
                { clear = true }
            )

            vim.api.nvim_create_autocmd({ "BufEnter" }, {
                group = group,
                pattern = "*.md",
                desc = "Setup notes nvim-cmp source",
                callback = function()
                    if obs.vault:is_current_buffer_in_vault() then
                        require("cmp").setup.buffer {
                            sources = {
                                { name = "obs" },
                                { name = "luasnip" },
                            },
                        }
                    end
                end,
            })
        end,
    },
}
