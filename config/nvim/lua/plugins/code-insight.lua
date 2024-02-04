return {
    {
        "kevinhwang91/nvim-ufo",
        dependencies = {
            "kevinhwang91/promise-async",
            "nvim-treesitter/nvim-treesitter",
        },
        lazy = true,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = (" 󰁂 %d "):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        local hlGroup = chunk[2]
                        table.insert(newVirtText, { chunkText, hlGroup })
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix
                                .. (" "):rep(
                                    targetWidth - curWidth - chunkWidth
                                )
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, "MoreMsg" })
                return newVirtText
            end

            require("ufo").setup {
                fold_virt_text_handler = handler,
                provider_selector = function(bufnr, filetype, buftype)
                    return { "treesitter", "indent" }
                end,
            }

            vim.o.foldcolumn = "1"
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true

            vim.keymap.set("n", "zR", require("ufo").openAllFolds)
            vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
            vim.keymap.set("n", "<leader>k", function()
                local winid = require("ufo").peekFoldedLinesUnderCursor()
                if not winid then
                    vim.lsp.buf.hover()
                end
            end)
        end,
    },
    {
        "RRethy/vim-illuminate",
        config = function()
            require("illuminate").configure {
                modes_allowlist = { "n" },
            }
            vim.cmd [[
                augroup illuminate_augroup
                    autocmd!
                    autocmd VimEnter * hi illuminatedWordRead cterm=none gui=none guibg=#526252
                    autocmd VimEnter * hi illuminatedWordText cterm=none gui=none guibg=#525252
                    autocmd VimEnter * hi illuminatedWordWrite cterm=none gui=none guibg=#625252
                augroup END
            ]]
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = true,
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
            "nvim-treesitter/nvim-treesitter-context",
        },
        build = function()
            local ts_update = require("nvim-treesitter.install").update {
                with_sync = true,
            }
            ts_update()
        end,
        config = function()
            local ts_config = require "nvim-treesitter.configs"
            require("treesitter-context").setup {
                max_lines = 1,
            }

            ts_config.setup {
                ensure_installed = {
                    -- languages
                    "bash",
                    "clojure",
                    "fennel",
                    "go",
                    "gomod",
                    "gosum",
                    "groovy",
                    "java",
                    "javascript",
                    "kotlin",
                    "lua",
                    "python",
                    "rust",
                    "scheme",
                    "sql",
                    "tsx",
                    "vim",
                    -- markup
                    "css",
                    "html",
                    "markdown",
                    "markdown_inline",
                    "mermaid",
                    "xml",
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
                    "ssh_config",
                    "printf",
                    "disassembly",
                    "dockerfile",
                    "git_config",
                    "git_rebase",
                    "gitcommit",
                    "gitignore",
                    "http",
                    "query",
                },
                highlight = {
                    enable = true,
                    disable = function(lang, buf)
                        local max_filesize = 100 * 1024 -- 100 KB
                        local ok, stats = pcall(
                            vim.loop.fs_stat,
                            vim.api.nvim_buf_get_name(buf)
                        )
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                    end,
                    additional_vim_regex_highlighting = false,
                },
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["a="] = {
                                query = "@assignment.outer",
                                desc = "Select outer part of an assignment",
                            },
                            ["i="] = {
                                query = "@assignment.inner",
                                desc = "Select inner part of an assignment",
                            },
                            ["l="] = {
                                query = "@assignment.lhs",
                                desc = "Select left hand side of an assignment",
                            },
                            ["r="] = {
                                query = "@assignment.rhs",
                                desc = "Select right hand side of an assignment",
                            },

                            ["aa"] = {
                                query = "@parameter.outer",
                                desc = "Select outer part of a parameter/argument",
                            },
                            ["ia"] = {
                                query = "@parameter.inner",
                                desc = "Select inner part of a parameter/argument",
                            },

                            ["ai"] = {
                                query = "@conditional.outer",
                                desc = "Select outer part of a conditional",
                            },
                            ["ii"] = {
                                query = "@conditional.inner",
                                desc = "Select inner part of a conditional",
                            },

                            ["al"] = {
                                query = "@loop.outer",
                                desc = "Select outer part of a loop",
                            },
                            ["il"] = {
                                query = "@loop.inner",
                                desc = "Select inner part of a loop",
                            },

                            ["am"] = {
                                query = "@call.outer",
                                desc = "Select outer part of a function call",
                            },
                            ["im"] = {
                                query = "@call.inner",
                                desc = "Select inner part of a function call",
                            },

                            ["af"] = {
                                query = "@function.outer",
                                desc = "Select outer part of a method/function definition",
                            },
                            ["if"] = {
                                query = "@function.inner",
                                desc = "Select inner part of a method/function definition",
                            },

                            ["ac"] = {
                                query = "@class.outer",
                                desc = "Select outer part of a class",
                            },
                            ["ic"] = {
                                query = "@class.inner",
                                desc = "Select inner part of a class",
                            },

                            ["an"] = {
                                query = "@block.outer",
                                desc = "Select inner part of a block",
                            },
                            ["in"] = {
                                query = "@block.inner",
                                desc = "Select outer part of a block",
                            },
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = true,
                        goto_next_start = {
                            ["]m"] = "@function.outer",
                        },
                        goto_next_end = {
                            ["]M"] = "@function.outer",
                        },
                        goto_previous_start = {
                            ["[m"] = "@function.outer",
                        },
                        goto_previous_end = {
                            ["[M"] = "@function.outer",
                        },
                    },
                    swap = {
                        enable = true,
                        swap_next = {
                            ["<leader>man"] = "@parameter.inner",
                            ["<leader>mfn"] = "@function.outer",
                            ["<leader>mcn"] = "@class.outer",
                        },
                        swap_previous = {
                            ["<leader>map"] = "@parameter.inner",
                            ["<leader>mfp"] = "@function.outer",
                            ["<leader>mcp"] = "@class.outer",
                        },
                    },
                },
            }

            vim.keymap.set("n", "[c", function()
                require("treesitter-context").go_to_context(vim.v.count1)
            end, { silent = true })
            local parser_config =
                require("nvim-treesitter.parsers").get_parser_configs()
            parser_config.tsx.filetype_to_parsername =
                { "javascript", "typescript.tsx" }
        end,
    },
    {
        "nvim-treesitter/playground",
        lazy = true,
        cmd = {
            "TSPlaygroundToggle",
        },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
    },
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
    },
    {
        "folke/todo-comments.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("todo-comments").setup {
                keywords = {
                    TODO = {
                        alt = { "todo" },
                    },
                },
                search = {
                    args = {
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--hidden",
                    },
                },
            }

            vim.keymap.set("n", "]t", function()
                require("todo-comments").jump_next()
            end, { desc = "Next todo comment" })

            vim.keymap.set("n", "[t", function()
                require("todo-comments").jump_prev()
            end, { desc = "Previous todo comment" })

            vim.keymap.set(
                "n",
                "<leader>ft",
                ":TodoTelescope<CR>",
                { desc = "find todos in project" }
            )
        end,
    },
}
