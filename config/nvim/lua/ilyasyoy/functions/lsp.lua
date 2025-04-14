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

function M.on_attach(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }

    vim.keymap.set(
        "n",
        "grD",
        vim.lsp.buf.declaration,
        described(bufopts, "go to Declarations")
    )
    vim.keymap.set("n", "grs", function()
        vim.lsp.buf.typehierarchy "subtypes"
    end, described(bufopts, "go to subtypes"))
    vim.keymap.set("n", "grS", function()
        vim.lsp.buf.typehierarchy "supertypes"
    end, described(bufopts, "go to supertypes"))
    vim.keymap.set("n", "<C-s>", vim.lsp.buf.signature_help)
    vim.keymap.set(
        "n",
        "grd",
        vim.lsp.buf.definition,
        described(bufopts, "go to definitions")
    )
    vim.keymap.set(
        "n",
        "<space>wa",
        vim.lsp.buf.add_workspace_folder,
        described(bufopts, "workspace add folder")
    )
    vim.keymap.set(
        "n",
        "<space>wr",
        vim.lsp.buf.remove_workspace_folder,
        described(bufopts, "workspace remove folder")
    )
    vim.keymap.set("n", "<space>lw", function()
        vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, described(bufopts, "workspace list folders"))

    if client then
        if client.server_capabilities.codeLensProvider then
            vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
                group = vim.api.nvim_create_augroup("CodeLenses", {}),
                pattern = {
                    -- NOTE: Here I list filetype that I wanna use with codelens.
                    -- commented lines seem to do nothing, but have lens enabled
                    "*.go",
                    "*.mod",
                    -- "*.java",
                    -- "*.py",
                    -- "*.lua",
                },
                callback = function()
                    vim.lsp.codelens.refresh { bufnr = 0 }
                end,
            })
            vim.api.nvim_buf_set_keymap(
                bufnr,
                "n",
                "<leader>lclR",
                "<Cmd>lua vim.lsp.codelens.refresh { bufnr = 0 }<CR>",
                { silent = true }
            )
            vim.api.nvim_buf_set_keymap(
                bufnr,
                "n",
                "<leader>lclr",
                "<Cmd>lua vim.lsp.codelens.run()<CR>",
                { silent = true }
            )
        end
        client.server_capabilities.semanticTokensProvider = nil
        if
            client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint
        then
            vim.keymap.set("n", "<leader>lih", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
            end, described(bufopts, "Toggle Inlay Hints"))
        end
    end
end

function M.get_capabilities()
    return require("cmp_nvim_lsp").default_capabilities()
end

return M
