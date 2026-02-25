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

    vim.keymap.set({ "n", "v" }, "<localleader>oc", function()
        vim.lsp.buf.format { async = false, timeout_ms = 10000 }
    end, described(bufopts, "organize code"))

    vim.keymap.set(
        "n",
        "<localleader>d",
        vim.diagnostic.open_float,
        described(bufopts, "diagnostics")
    )
    vim.keymap.set("n", "<localleader>lr", "<cmd>LspRestart<cr>", described(bufopts, "restart lsp"))

    local client = vim.lsp.get_client_by_id(data.data.client_id)
    if not client then
        return
    end

    if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
        vim.keymap.set("n", "<localleader>lih", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, described(bufopts, "Toggle Inlay Hints"))
    end

    client.server_capabilities.semanticTokensProvider = nil

    if client.name == "jdtls" then
        require("jdtls").setup_dap()
    end

    if client.name == "tinymist" then
        vim.api.nvim_buf_create_user_command(0, "TypstPreview", function()
            vim.lsp.buf.execute_command {
                command = "tinymist.startDefaultPreview",
                arguments = {},
            }
        end, {
            desc = "Start typst preview using tinymist",
        })
    end
end

return {
    {
        "neovim/nvim-lspconfig",
        event = "VeryLazy",
        config = function()
            vim.lsp.config("gopls", {
                settings = {
                    gopls = {
                        gofumpt = true,
                        completeUnimported = true,
                        usePlaceholders = false,
                        staticcheck = true,
                    },
                },
            })
            vim.lsp.config("tinymist", {
                settings = {
                    preview = {
                        background = {
                            enabled = true,
                        },
                    },
                    formatterMode = "typstyle",
                },
            })

            for _, server in ipairs {
                "bashls",
                "ts_ls",
                "lua_ls",
                "basedpyright",
                "gopls",
                "tinymist",
                "kotlin_lsp",
            } do
                vim.lsp.enable(server)
            end

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("ilyasyoy.lsp", {}),
                callback = lsp_attach,
            })
        end,
    },
}
