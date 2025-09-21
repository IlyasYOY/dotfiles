local M = {}

---describes argument, useful in mapping when you have *prototype*-like mapping
---options.
---@param x table
---@param desc string
---@return table
function M.described(x, desc)
    return vim.tbl_extend("force", x, { desc = desc })
end

local described = M.described

function M.lsp_attach(data)
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

function M.get_capabilities()
    return require("cmp_nvim_lsp").default_capabilities()
end

return M
