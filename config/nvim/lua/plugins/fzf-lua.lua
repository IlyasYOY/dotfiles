local core = require "ilyasyoy.functions.core"

return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local fzf = require "fzf-lua"
        local fzf_utils = require "fzf-lua.utils"

        fzf.setup {
            winopts = {
                fullscreen = true,
            },
            git = {
                branches = {
                    actions = {
                        ["ctrl-d"] = function(selected)
                            vim.cmd.Git("difftool --name-only " .. selected[1])
                        end,
                    },
                },
            },
        }

        fzf.register_ui_select()

        vim.keymap.set("n", "<leader>fr", function()
            fzf.resume()
        end, { desc = "find resume" })

        vim.keymap.set("n", "<leader>ff", function()
            fzf.files()
        end, { desc = "find files" })

        vim.keymap.set("n", "<leader>fF", function()
            fzf.files {
                cwd = core.string_strip_prefix(vim.fn.expand "%:p:h", "oil://"),
            }
        end, { desc = "find files in current dir" })

        vim.keymap.set("n", "<leader>fg", function()
            fzf.live_grep()
        end, { desc = "find grep through files" })

        vim.keymap.set("v", "<leader>fg", function()
            fzf.live_grep {
                search = fzf_utils.get_visual_selection(),
            }
        end, { desc = "find grep through files" })

        vim.keymap.set("n", "<leader>fG", function()
            fzf.live_grep {
                cwd = core.string_strip_prefix(vim.fn.expand "%:p:h", "oil://"),
            }
        end, { desc = "find files in current dir" })

        vim.keymap.set("v", "<leader>fG", function()
            fzf.live_grep {
                cwd = core.string_strip_prefix(vim.fn.expand "%:p:h", "oil://"),
                search = fzf_utils.get_visual_selection(),
            }
        end, { desc = "find files in current dir" })

        vim.keymap.set("n", "<leader>fa", function()
            vim.cmd [[FzfLua]]
        end, { desc = "find in commands" })

        vim.keymap.set("n", "<leader>fq", function()
            fzf.quickfix()
        end, { desc = "find in quickfix" })

        vim.keymap.set("n", "<leader>fQ", function()
            fzf.quickfix_stack()
        end, { desc = "find in quickfix stack" })

        vim.keymap.set("n", "<leader>fl", function()
            fzf.loclist()
        end, { desc = "find in loc list" })

        vim.keymap.set("n", "<leader>fL", function()
            fzf.loclist()
        end, { desc = "find in loc list stack" })

        vim.keymap.set("n", "<leader>fs", function()
            fzf.lsp_document_symbols()
        end, { desc = "find document symbols" })

        vim.keymap.set("n", "<leader>fS", function()
            fzf.lsp_live_workspace_symbols()
        end, { desc = "find workspace symbols" })

        vim.keymap.set("n", "<leader>fd", function()
            fzf.diagnostics_document()
        end, { desc = "find document diagnostics" })

        vim.keymap.set("n", "<leader>fD", function()
            fzf.diagnostics_workspace()
        end, { desc = "find workspace diagnostics" })

        vim.keymap.set("n", "<leader>fm", function()
            fzf.manpages()
        end, { desc = "find man pager" })

        vim.keymap.set("n", "<leader>fh", function()
            fzf.helptags()
        end, { desc = "find help tags" })

        vim.keymap.set("n", "<leader>fb", function()
            fzf.buffers()
        end, { desc = "find buffers" })
    end,
}
