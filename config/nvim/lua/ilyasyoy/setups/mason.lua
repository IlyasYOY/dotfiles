local mason = require "mason"

mason.setup {
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
        },
    },
}

require("mason-lspconfig").setup {
    ensure_installed = {
        "gopls",
        "gradle_ls",
        "jdtls",
        "sumneko_lua",
        "pyright",
        "rust_analyzer",
        "tsserver",
    },
    automatic_installation = true,
}

require("mason-nvim-dap").setup {
    ensure_installed = { "python" },
}

require("mason-null-ls").setup {
    ensure_installed = {
        "stylua",
        "luacheck",
        "jsonlint",
        "yamllint",
        "markdownlint",
    },
}
