return {
    {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
            local null_ls = require "null-ls"
            local core = require "ilyasyoy.functions.core"

            local function with_root_file(builtin, file)
                return builtin.with {
                    condition = function(utils)
                        return utils.root_has_file(file)
                    end,
                }
            end

            null_ls.setup {
                debounce = 150,
                save_after_format = false,
                sources = {
                    with_root_file(
                        null_ls.builtins.formatting.stylua,
                        "stylua.toml"
                    ),
                    with_root_file(
                        null_ls.builtins.diagnostics.luacheck,
                        ".luacheckrc"
                    ),

                    null_ls.builtins.diagnostics.jsonlint,
                    null_ls.builtins.diagnostics.yamllint,

                    null_ls.builtins.diagnostics.pylint,
                    null_ls.builtins.formatting.isort,
                    null_ls.builtins.formatting.autopep8,

                    with_root_file(
                        null_ls.builtins.formatting.prettier,
                        ".prettierrc.js"
                    ),
                    with_root_file(
                        null_ls.builtins.formatting.stylelint,
                        ".stylelintrc.js"
                    ),
                    with_root_file(
                        null_ls.builtins.code_actions.eslint_d,
                        ".eslintrc.js"
                    ),

                    null_ls.builtins.diagnostics.checkstyle.with {
                        args = { "-f", "sarif", "$FILENAME" },
                        extra_args = {
                            "-c",
                            core.resolve_realative_to_dotfiles_dir "config/checkstyle.xml",
                        },
                    },
                    null_ls.builtins.diagnostics.pmd.with {
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
