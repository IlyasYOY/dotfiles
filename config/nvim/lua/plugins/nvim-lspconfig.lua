local lsp = require "ilyasyoy.functions.lsp"

local described = lsp.described

local opts = { noremap = true, silent = true }

local function config_go()
    local hints = vim.empty_dict()
    hints.assignVariableTypes = true
    hints.compositeLiteralFields = true
    hints.compositeLiteralTypes = true
    hints.constantValues = true
    hints.functionTypeParameters = true
    hints.parameterNames = true
    hints.rangeVariableTypes = true
    vim.lsp.config("gopls", {
        settings = {
            gopls = {
                buildFlags = { "-tags=e2e" },
                codelenses = {
                    test = true,
                    gc_details = true,
                    generate = true,
                    run_govulncheck = true,
                    tidy = true,
                    upgrade_dependency = true,
                    vendor = true,
                },
                gofumpt = true,
                completeUnimported = true,
                usePlaceholders = false,
                diagnosticsDelay = "250ms",
                staticcheck = true,
                hints = hints,
                analyses = {
                    recursiveiter = true,
                    maprange = true,
                    framepointer = true,
                    modernize = true,
                    nilness = true,
                    hostport = true,
                    gofix = true,
                    sigchanyzer = true,
                    stdversion = true,
                    unreachable = true,
                    unusedfunc = true,
                    unusedparams = true,
                    unusedvariable = true,
                    unusedwrite = true,
                    useany = true,
                },
            },
        },
    })
end

return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "folke/lazydev.nvim",
        },
        config = function()
            -- HACK: This sucker dosn't work if I add it as a simple plugin due
            -- to lazy.nvim's 'lazy' nature.
            require("lazydev").setup()

            config_go()

            for _, server in ipairs {
                "bashls",
                "ts_ls",
                "lua_ls",
                "basedpyright",
                "gopls",
            } do
                vim.lsp.enable(server)
            end

            local bufopts = { noremap = true, silent = true }

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("ilyasyoy.lsp", {}),
                callback = lsp.lsp_attach,
            })

            vim.keymap.set(
                "n",
                "<leader>d",
                vim.diagnostic.open_float,
                described(opts, "diagnostics")
            )

            vim.keymap.set({ "n", "v" }, "<localleader>oc", function()
                vim.lsp.buf.format { async = false, timeout_ms = 10000 }
            end, described(bufopts, "organize code"))

            vim.keymap.set("n", "<leader>lr", "<cmd>LspRestart<cr>")

            vim.lsp.handlers["textDocument/hover"] =
                vim.lsp.with(vim.lsp.handlers.hover, {
                    border = "single",
                })
        end,
    },
}
