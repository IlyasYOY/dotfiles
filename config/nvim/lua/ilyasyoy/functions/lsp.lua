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

    if pcall(require, "telescope") then
        local telescope = require "telescope.builtin"
        local themes = require "telescope.themes"

        local function get_ivy(func)
            return function(...)
                return func(themes.get_ivy(), ...)
            end
        end

        vim.keymap.set(
            "n",
            "<leader>S",
            get_ivy(telescope.lsp_document_symbols),
            described(bufopts, "telescope Show Document Symbols")
        )
        vim.keymap.set(
            "n",
            "<leader>s",
            get_ivy(telescope.lsp_dynamic_workspace_symbols),
            described(bufopts, "telescope Show Workspace Symbols")
        )
    else
        vim.keymap.set(
            "n",
            "<leader>s",
            vim.lsp.buf.workspace_symbol,
            described(bufopts, "Show Workspace Symbols")
        )
    end

    vim.keymap.set(
        "n",
        "gD",
        vim.lsp.buf.declaration,
        described(bufopts, "go to Declarations")
    )
    vim.keymap.set("n", "gs", function()
        vim.lsp.buf.typehierarchy "subtypes"
    end, described(bufopts, "go to subtypes"))
    vim.keymap.set("n", "gS", function()
        vim.lsp.buf.typehierarchy "supertypes"
    end, described(bufopts, "go to supertypes"))
    vim.keymap.set(
        "n",
        "gd",
        vim.lsp.buf.definition,
        described(bufopts, "go to definitions")
    )
    vim.keymap.set(
        "n",
        "gr",
        vim.lsp.buf.references,
        described(bufopts, "go to references")
    )
    vim.keymap.set(
        "n",
        "gi",
        vim.lsp.buf.implementation,
        described(bufopts, "go to implementations")
    )
    vim.keymap.set(
        { "n", "i" },
        "<C-s>",
        vim.lsp.buf.signature_help,
        described(bufopts, "Help with signature")
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

    vim.keymap.set(
        "n",
        "<space>rn",
        vim.lsp.buf.rename,
        described(bufopts, "rename symbol under the cursor")
    )

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
