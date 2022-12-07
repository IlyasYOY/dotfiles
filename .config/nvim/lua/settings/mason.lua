local mason = require "mason"

mason.setup {
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
        }
    }
}

require("mason-lspconfig").setup {
    ensure_installed = { "gopls", "gradle_ls", "jdtls", "sumneko_lua", "pyright", "rust_analyzer" },
    automatic_installation = true
}
