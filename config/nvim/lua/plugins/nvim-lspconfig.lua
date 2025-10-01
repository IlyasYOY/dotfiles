local function described(x, desc)
    return vim.tbl_extend("force", x, { desc = desc })
end

local opts = { noremap = true, silent = true }

local function lsp_attach(data)
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = data.buf }

    vim.keymap.set("n", "<C-s>", vim.lsp.buf.signature_help)
    vim.keymap.set("n", "grs", function()
        vim.lsp.buf.typehierarchy "subtypes"
    end, described(bufopts, "go to subtypes"))
    vim.keymap.set("n", "grS", function()
        vim.lsp.buf.typehierarchy "supertypes"
    end, described(bufopts, "go to supertypes"))
    vim.keymap.set(
        "n",
        "grd",
        vim.lsp.buf.definition,
        described(bufopts, "go to definitions")
    )

    local client = vim.lsp.get_client_by_id(data.data.client_id)
    if not client then
        return
    end

    if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
        vim.keymap.set("n", "<localleader>lih", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, described(bufopts, "Toggle Inlay Hints"))
    end

    if client.name == "jdtls" then
        require("jdtls").setup_dap()
    end
end

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
                buildFlags = { "-tags=e2e,integration" },
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
                callback = lsp_attach,
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
