local described = require("ilyasyoy.functions.core").described

local M = {}

function M.on_attach(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }

    vim.keymap.set(
        "n",
        "gD",
        vim.lsp.buf.declaration,
        described(bufopts, "[g]o to [D]eclarations")
    )
    vim.keymap.set(
        "n",
        "gd",
        vim.lsp.buf.definition,
        described(bufopts, "[g]o to [d]efinitions")
    )
    vim.keymap.set(
        "n",
        "gr",
        vim.lsp.buf.references,
        described(bufopts, "[g]o to [r]eferences")
    )
    vim.keymap.set(
        "n",
        "gi",
        vim.lsp.buf.implementation,
        described(bufopts, "[g]o to [i]mplementations")
    )

    vim.keymap.set(
        "n",
        "<leader>S",
        vim.lsp.buf.workspace_symbol,
        described(bufopts, "Show [S]ymbols")
    )

    vim.keymap.set(
        "n",
        "<leader>h",
        vim.lsp.buf.hover,
        described(bufopts, "show [h]over")
    )
    vim.keymap.set(
        { "n", "i" },
        "<C-s>",
        vim.lsp.buf.signature_help,
        described(bufopts, "Help with [s]ignature")
    )

    vim.keymap.set(
        "n",
        "<space>wa",
        vim.lsp.buf.add_workspace_folder,
        described(bufopts, "[w]orkspace [a]dd folder")
    )
    vim.keymap.set(
        "n",
        "<space>wr",
        vim.lsp.buf.remove_workspace_folder,
        described(bufopts, "[w]orkspace [r]emove folder")
    )
    vim.keymap.set("n", "<space>wl", function()
        vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, described(bufopts, "[w]orkspace [l]ist folders"))

    vim.keymap.set(
        "n",
        "<space>rn",
        vim.lsp.buf.rename,
        described(bufopts, "[r]ename symbol under the cursor")
    )

    vim.keymap.set({ "n", "v" }, "<space>oc", function()
        vim.lsp.buf.format { async = true }
    end, described(bufopts, "[o]rganize [c]ode"))

    vim.keymap.set(
        "n",
        "<space>a",
        vim.lsp.buf.code_action,
        described(bufopts, "Perform code [a]ction")
    )
    vim.keymap.set(
        "v",
        "<space>a",
        vim.lsp.buf.code_action,
        described(bufopts, "Perform code [a]ction")
    )
end

function M.get_capabilities()
    return require("cmp_nvim_lsp").default_capabilities()
end

return M
