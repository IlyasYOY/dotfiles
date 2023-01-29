local function setup_generic()
    local lsp = require "ilyasyoy.functions.lsp"
    local lspconfig = require "lspconfig"

    local described = lsp.described

    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    local opts = { noremap = true, silent = true }
    vim.keymap.set(
        "n",
        "<leader>d",
        vim.diagnostic.open_float,
        described(opts, "[d]iagnostics")
    )
    vim.keymap.set(
        "n",
        "[d",
        vim.diagnostic.goto_prev,
        described(opts, "Previous [d]iagostics")
    )
    vim.keymap.set(
        "n",
        "]d",
        vim.diagnostic.goto_next,
        described(opts, "Next [d]iagnostics")
    )
    vim.keymap.set(
        "n",
        "<leader>dl",
        vim.diagnostic.setloclist,
        described(opts, "Put [d]iagnostics to [q]uickfix list")
    )

    local generic_servers =
        { "gopls", "gradle_ls", "pyright", "rust_analyzer", "tsserver" }
    for _, client in ipairs(generic_servers) do
        lspconfig[client].setup {
            on_attach = lsp.on_attach,
            capabilities = lsp.get_capabilities(),
        }
    end
end

local function setup_java()
    local Path = require "plenary.path"
    local coredor = require "coredor"
    local lsp = require "ilyasyoy.functions.lsp"
    local lspconfig = require "lspconfig"

    -- loads jdks from sdkman.
    -- TODO: fully refactor to plenary
    --
    ---@param version string java version to search for
    local function get_java_dir(version)
        local sdkman_dir = Path.path.home .. "/.sdkman/candidates/java/"
        local java_dirs = vim.fn.readdir(sdkman_dir, function(file)
            if coredor.string_has_prefix(file, version) then
                return 1
            end
        end)

        local java_dir = java_dirs[1]
        if not java_dir then
            error(string.format("No %s java version was found", version))
        end

        return sdkman_dir .. java_dir
    end

    lspconfig.jdtls.setup {
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
        settings = {
            java = {
                eclipse = {
                    downloadSources = true,
                },
                completion = {
                    favouriteStaticMembers = {
                        "java.util.Objects.*",
                        "org.junit.jupiter.api.Assertions.*",
                        "org.junit.jupiter.api.Assumptions.*",
                    },
                    guessMethodArguments = false,
                },
                configuration = {
                    runtimes = {
                        {
                            name = "JavaSE-1.8",
                            path = get_java_dir "8",
                        },
                        {
                            name = "JavaSE-11",
                            path = get_java_dir "11",
                        },
                        {
                            name = "JavaSE-17",
                            path = get_java_dir "17",
                        },
                    },
                },
            },
        },
    }
end

local function setup_lua()
    local coredor = require "coredor"
    local lsp = require "ilyasyoy.functions.lsp"
    local lspconfig = require "lspconfig"

    local library = {}
    local path = coredor.string_split(package.path, ";")

    -- this is the ONLY correct way to setup your path
    table.insert(path, "lua/?.lua")
    table.insert(path, "lua/?/init.lua")

    local function add(lib)
        for _, p in pairs(vim.fn.expand(lib, false, true)) do
            p = vim.loop.fs_realpath(p)
            if p then
                library[p] = true
            end
        end
    end

    -- add runtime
    add "$VIMRUNTIME"
    -- add plugins
    -- if you're not using packer, then you might need to change the paths below
    add "~/.local/share/nvim/site/pack/packer/opt/*"
    add "~/.local/share/nvim/site/pack/packer/start/*"

    lspconfig.sumneko_lua.setup {
        on_attach = lsp.on_attach,
        capabilities = lsp.get_capabilities(),
        settings = {
            Lua = {
                runtime = { version = "LuaJIT", path = path },
                diagnostics = {
                    globals = {
                        "vim",
                        -- Tests
                        "assert",
                        "describe",
                        "it",
                        "before_each",
                        "after_each",
                        "pending",
                        "clear",

                        "G_P",
                        "G_R",
                    },
                },
                format = {
                    enable = false,
                },
                workspace = {
                    library = library,
                    checkThirdParty = false,
                },
                telemetry = {
                    enable = false,
                },
            },
        },
    }
end

return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "IlyasYOY/coredor.nvim",
        },
        config = function()
            setup_generic()
            setup_lua()
            setup_java()
        end,
    },
    "onsails/lspkind.nvim",
    {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
            local null_ls = require "null-ls"

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
                },
            }
        end,
    },
    {
        "simrat39/symbols-outline.nvim",
        config = function()
            local outline = require "symbols-outline"

            outline.setup()

            vim.keymap.set("n", "<leader>O", function()
                outline.toggle_outline()
            end, { desc = "Opens [O]utline", silent = true })
        end,
    },
}
