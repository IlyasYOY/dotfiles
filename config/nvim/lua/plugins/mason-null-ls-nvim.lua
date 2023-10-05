return {
    {
        "jayp0521/mason-null-ls.nvim",
        dependencies = {
            "williamboman/mason.nvim",
        },
        config = function()
            require("mason-null-ls").setup {
                ensure_installed = {
                    "stylua",
                    "luacheck",
                    "jsonlint",
                    "yamllint",
                    "pylint",
                    "autopep8",
                    "isort",
                    "prettier",
                    "stylelint",
                    "eslint_d",
                    "checkstyle",
                },
                automatic_installation = false,
            }
        end,
    },
}
