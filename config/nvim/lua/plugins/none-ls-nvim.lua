local function find_first_present_file(fileList)
    for _, filePath in ipairs(fileList) do
        if vim.fn.filereadable(filePath) == 1 then
            return filePath
        end
    end
    return nil
end

return {
    {
        "nvimtools/none-ls.nvim",
        dependencies = {
            "gbprod/none-ls-luacheck.nvim",
        },
        config = function()
            local none_ls = require "null-ls"
            local h = require "null-ls.helpers"
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
                sources = {
                    -- markdown
                    none_ls.builtins.diagnostics.markdownlint.with {
                        method = none_ls.methods.DIAGNOSTICS_ON_SAVE,
                    },
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
                    none_ls.builtins.diagnostics.sqlfluff.with {
                        extra_args = { "--dialect", "postgres" },
                    },

                    -- proto
                    none_ls.builtins.diagnostics.protolint,
                    none_ls.builtins.formatting.buf,
                    none_ls.builtins.diagnostics.buf,

                    -- go

                    -- NOTE: wanna try working without them for now.
                    --
                    -- none_ls.builtins.formatting.golines.with {
                    --     extra_args = {
                    --         "--base-formatter=goimports -format-only=true",
                    --     },
                    -- },
                    none_ls.builtins.formatting.gofumpt,
                    none_ls.builtins.formatting.goimports.with {
                        extra_args = {
                            "-format-only=true",
                        },
                    },
                    none_ls.builtins.diagnostics.golangci_lint.with {
                        extra_args = {
                            "--config="
                                .. find_first_present_file {
                                    "./.golangci.pipeline.yaml",
                                    "./.golangci.yml",
                                    core.resolve_relative_to_dotfiles_dir "./config/.golangci.yml",
                                },
                        },
                        prefer_local = "bin",
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
                            core.resolve_relative_to_dotfiles_dir "config/checkstyle.xml",
                        },
                    },
                    none_ls.builtins.diagnostics.pmd.with {
                        ignore_stderr = true,
                        args = {
                            "check",
                            "--format",
                            "json",
                            "--no-cache",
                            "--dir",
                            "$FILENAME",
                        },
                        extra_args = {
                            "-R",
                            core.resolve_relative_to_dotfiles_dir "config/pmd.xml",
                        },
                    },
                },
            }
        end,
    },
}
