return {
    {
        "mfussenegger/nvim-dap-python",
        lazy = true,
        config = function()
            require("dap-python").setup()
        end,
    },
}
