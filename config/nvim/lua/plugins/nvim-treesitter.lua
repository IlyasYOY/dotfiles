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

                        vim.keymap.set({ "o", "x" }, "=r", function()
                            ts_select.select_textobject(
                                "@assignment.rhs",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "o", "x" }, "aa", function()
                            ts_select.select_textobject(
                                "@parameter.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "o", "x" }, "ia", function()
                            ts_select.select_textobject(
                                "@parameter.inner",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "o", "x" }, "ai", function()
                            ts_select.select_textobject(
                                "@conditional.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "o", "x" }, "ii", function()
                            ts_select.select_textobject(
                                "@conditional.inner",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "o", "x" }, "af", function()
                            ts_select.select_textobject(
                                "@function.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "o", "x" }, "if", function()
                            ts_select.select_textobject(
                                "@function.inner",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "o", "x" }, "at", function()
                            ts_select.select_textobject(
                                "@class.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "o", "x" }, "it", function()
                            ts_select.select_textobject(
                                "@class.inner",
                                "textobjects"
                            )
                        end)
                    end

                    local function setup_moves()
                        local ts_moves =
                            require "nvim-treesitter-textobjects.move"
                        vim.keymap.set({ "n", "o", "x" }, "]f", function()
                            ts_moves.goto_next_start(
                                "@function.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "n", "o", "x" }, "]F", function()
                            ts_moves.goto_next_end(
                                "@function.outer",
                                "textobjects"
                            )
                        end)

                        vim.keymap.set({ "n", "o", "x" }, "[f", function()
                            ts_moves.goto_previous_start(
                                "@function.outer",
                                "textobjects"
                            )
                        end)
                        vim.keymap.set({ "n", "o", "x" }, "[F", function()
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

                    local ts_group =
                        vim.api.nvim_create_augroup("ilyasyoy-treesitter", {})

                    vim.api.nvim_create_autocmd("FileType", {
                        pattern = {
                            "go",
                            "gomod",
                            "gosum",
                            "java",
                            "lua",
                            "make",
                            "markdown",
                            "proto",
                            "python",
                            "query",
                            "sql",
                            "typescript",
                            "typst",
                            "vim",
                            "yaml",
                        },
                        callback = function(args)
                            vim.treesitter.start()

                            setup_selects()
                            setup_moves()
                            setup_swaps()

                            local ft = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
                            vim.opt_local.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

                            vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                            vim.opt_local.foldmethod = 'expr'

                            vim.opt_local.foldcolumn = "1"
                            vim.opt_local.foldlevel = 99
                            vim.opt_local.foldlevelstart = 99
                            vim.opt_local.foldenable = true
                        end,
                        group = ts_group,
                    })
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
                "make",
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
                "typst",
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
