local function find_first_present_file(fileList)
    for _, filePath in ipairs(fileList) do
        if vim.fn.filereadable(filePath) == 1 then
            return filePath
        end
    end
    return nil
end

local function golang_ci_link_config()
    local core = require "ilyasyoy.functions.core"

    local config_path = find_first_present_file {
        "./.golangci.pipeline.yaml",
        "./.golangci.yml",
        core.resolve_relative_to_dotfiles_dir "./config/.golangci.yml",
    }

    local config = {
        prefer_local = "bin",
        timeout = 60 * 1000,
    }
    if config_path then
        config.extra_args = {
            "--config=" .. config_path,
        }
    end
    return config
end

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
                    none_ls.builtins.diagnostics.buf,

                    -- go
                    none_ls.builtins.formatting.gofumpt,
                    none_ls.builtins.diagnostics.golangci_lint.with(
                        golang_ci_link_config()
                    ),
                    none_ls.builtins.code_actions.impl,
                    none_ls.builtins.code_actions.gomodifytags,

                    -- python
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
