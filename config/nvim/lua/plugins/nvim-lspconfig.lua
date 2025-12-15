local function described(x, desc)
    return vim.tbl_extend("force", x, { desc = desc })
end

local opts = { noremap = true, silent = true }

local function lsp_attach(data)
    local bufopts = { noremap = true, silent = true, buffer = data.buf }
    vim.lsp.completion.enable(true, data.data.client_id, data.buf)

    -- I need this to enable omnifunc expanding snippets.
    -- <c-y> expands snippets with side effects;
    -- this is built-in neovim snippets & autocompletion functionality.
    vim.keymap.set("i", "<CR>", function()
        if vim.fn.pumvisible() ~= 0 then
            return "<C-y>"
        end
        return "<CR>"
    end, {
        buffer = data.buf,
        expr = true,
    })

    vim.keymap.set("n", "<C-s>", vim.lsp.buf.signature_help, bufopts)
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
    vim.keymap.set(
        "n",
        "grD",
        vim.lsp.buf.declaration,
        described(bufopts, "go to declaration")
    )
    vim.keymap.set(
        "n",
        "grt",
        vim.lsp.buf.type_definition,
        described(bufopts, "go to type definition")
    )
    vim.keymap.set(
        "n",
        "grT",
        vim.lsp.buf.typehierarchy,
        described(bufopts, "go to typehierarchy")
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
        event = "VeryLazy",
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
                "kotlin_lsp",
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
        end,
    },
}
