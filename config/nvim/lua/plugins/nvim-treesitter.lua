return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        dependencies = {
            {
                "nvim-treesitter/nvim-treesitter-textobjects",
                branch = "main",
                config = function()
                    vim.g.no_plugin_maps = true

                    require("nvim-treesitter-textobjects").setup {
                        select = {
                            lookahead = true,
                            include_surrounding_whitespace = false,
                        },
                        move = {
                            set_jumps = true,
                        },
                    }

                    local function setup_selects()
                        local ts_select =
                            require "nvim-treesitter-textobjects.select"

                        vim.keymap.set({ "x", "o" }, "r=", function()
                            ts_select.select_textobject(
                                "@assignment.rhs",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "x", "o" }, "aa", function()
                            ts_select.select_textobject(
                                "@parameter.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "x", "o" }, "ia", function()
                            ts_select.select_textobject(
                                "@parameter.inner",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "x", "o" }, "ai", function()
                            ts_select.select_textobject(
                                "@conditional.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "x", "o" }, "ii", function()
                            ts_select.select_textobject(
                                "@conditional.inner",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "x", "o" }, "af", function()
                            ts_select.select_textobject(
                                "@function.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "x", "o" }, "if", function()
                            ts_select.select_textobject(
                                "@function.inner",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "x", "o" }, "at", function()
                            ts_select.select_textobject(
                                "@class.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "x", "o" }, "it", function()
                            ts_select.select_textobject(
                                "@class.inner",
                                "textobjects"
                            )
                        end)
                    end

                    local function setup_moves()
                        local ts_moves =
                            require "nvim-treesitter-textobjects.move"
                        vim.keymap.set({ "n", "x", "o" }, "]f", function()
                            ts_moves.goto_next_start(
                                "@function.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "n", "x", "o" }, "]F", function()
                            ts_moves.goto_next_end(
                                "@function.outer",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "n", "x", "o" }, "[f", function()
                            ts_moves.goto_previous_start(
                                "@function.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "n", "x", "o" }, "[F", function()
                            ts_moves.goto_previous_end(
                                "@function.outer",
                                "textobjects"
                            )
                        end)
                    end

                    local function setup_swaps()
                        local ts_swaps =
                            require "nvim-treesitter-textobjects.swap"

                        vim.keymap.set("n", "<leader>man", function()
                            ts_swaps.swap_next "@parameter.inner"
                        end)
                        vim.keymap.set("n", "<leader>map", function()
                            ts_swaps.swap_previous "@parameter.inner"
                        end)

                        vim.keymap.set("n", "<leader>mfn", function()
                            ts_swaps.swap_next "@function.inner"
                        end)
                        vim.keymap.set("n", "<leader>mfp", function()
                            ts_swaps.swap_previous "@function.inner"
                        end)
                    end

                    setup_selects()
                    setup_moves()
                    setup_swaps()
                end,
            },
            {
                "nvim-treesitter/nvim-treesitter-context",
                config = function()
                    local ts_context = require "treesitter-context"
                    ts_context.setup {
                        enable = true,
                        max_lines = 1,
                        line_numbers = true,
                    }

                    vim.keymap.set("n", "[c", function()
                        ts_context.go_to_context(vim.v.count1)
                    end, { silent = true })
                end,
            },
        },
        config = function()
            local ts = require "nvim-treesitter"

            ts.install {
                -- languages
                "bash",
                "c",
                "clojure",
                "fennel",
                "go",
                "gomod",
                "gosum",
                "groovy",
                "java",
                "javadoc",
                "javascript",
                "kotlin",
                "lua",
                "luadoc",
                "proto",
                "python",
                "rust",
                "scheme",
                "sql",
                "tsx",
                "typescript",
                "vim",
                "vimdoc",
                -- markup
                "css",
                "html",
                "markdown",
                "markdown_inline",
                "xml",
                "asm",
                -- config
                "dot",
                "toml",
                "yaml",
                -- data
                "csv",
                "json",
                "json5",
                -- utility
                "diff",
                "disassembly",
                "dockerfile",
                "git_config",
                "git_rebase",
                "gitcommit",
                "gitignore",
                "http",
                "mermaid",
                "printf",
                "query",
                "ssh_config",
            }

            vim.treesitter.language.register("javascript", "tsx")
            vim.treesitter.language.register("typescript.tsc", "tsx")
        end,
    },
}
