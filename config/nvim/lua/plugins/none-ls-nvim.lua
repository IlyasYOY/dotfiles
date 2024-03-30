return {
    {
        "nvimtools/none-ls.nvim",
        dependencies = {
            "gbprod/none-ls-luacheck.nvim",
        },
        config = function()
            local none_ls = require "null-ls"
            local core = require "ilyasyoy.functions.core"

            local function with_root_file(builtin, file)
                return builtin.with {
                    condition = function(utils)
                        return utils.root_has_file(file)
                    end,
                }
            end

            none_ls.register(
                with_root_file(
                    require "none-ls-luacheck.diagnostics.luacheck",
                    ".luacheckrc"
                )
            )

            none_ls.setup {
                debounce = 150,
                save_after_format = false,
                -- debug = true,
                sources = {
                    -- markdown
                    none_ls.builtins.diagnostics.markdownlint,
                    none_ls.builtins.formatting.markdownlint,

                    -- lua
                    with_root_file(
                        none_ls.builtins.formatting.stylua,
                        "stylua.toml"
                    ),

                    -- configs
                    none_ls.builtins.diagnostics.yamllint,

                    -- sql
                    none_ls.builtins.formatting.sqlfluff.with {
                        extra_args = { "--dialect", "postgres" },
                    },

                    -- go
                    none_ls.builtins.formatting.gofumpt,
                    none_ls.builtins.formatting.golines,
                    none_ls.builtins.formatting.goimports,
                    none_ls.builtins.diagnostics.golangci_lint.with {
                        extra_args = { "--config=~/.golangci.yml" },
                        timeout = 60 * 1000,
                    },
                    none_ls.builtins.code_actions.impl,
                    none_ls.builtins.code_actions.gomodifytags,

                    -- python
                    none_ls.builtins.diagnostics.pylint,
                    none_ls.builtins.formatting.isort,

                    -- front
                    with_root_file(
                        none_ls.builtins.formatting.prettier,
                        ".prettierrc.js"
                    ),
                    with_root_file(
                        none_ls.builtins.formatting.stylelint,
                        ".stylelintrc.js"
                    ),

                    -- java
                    none_ls.builtins.diagnostics.checkstyle.with {
                        args = { "-f", "sarif", "$FILENAME" },
                        extra_args = {
                            "-c",
                            core.resolve_realative_to_dotfiles_dir "config/checkstyle.xml",
                        },
                    },
                    none_ls.builtins.diagnostics.pmd.with {
                        args = {
                            "--format",
                            "json",
                            "--no-cache",
                            "--dir",
                            "$FILENAME",
                        },
                        extra_args = {
                            "-R",
                            core.resolve_realative_to_dotfiles_dir "config/pmd.xml",
                        },
                    },
                },
            }
        end,
    },
}
