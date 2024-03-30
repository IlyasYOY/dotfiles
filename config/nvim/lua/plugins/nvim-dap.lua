return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "theHamsta/nvim-dap-virtual-text",
        },
        lazy = true,
        config = function()
            local dap = require "dap"
            require("nvim-dap-virtual-text").setup()

            vim.keymap.set("n", "<F2>", function()
                dap.terminate()
            end, { desc = "Stop debugging" })

            vim.keymap.set("n", "<F5>", function()
                dap.continue()
            end, { desc = "Continue debugging" })

            vim.keymap.set("n", "<F6>", function()
                dap.repl.open()
            end, { desc = "Open REPL" })

            vim.keymap.set("n", "<F7>", function()
                dap.run_to_cursor()
            end, { desc = "Run debugging to cursor" })

            vim.keymap.set("n", "<F10>", function()
                dap.step_over()
            end, { desc = "Step over" })

            vim.keymap.set("n", "<F11>", function()
                dap.step_into()
            end, { desc = "Step into" })

            vim.keymap.set("n", "<F12>", function()
                dap.step_out()
            end, { desc = "Step out" })

            vim.keymap.set("n", "<leader>Db", function()
                dap.toggle_breakpoint()
            end, {
                desc = "Toggle Debug breakpoint",
            })

            vim.keymap.set("n", "<leader>DB", function()
                local condition = vim.fn.input "Breakpoint condition: "
                dap.set_breakpoint(condition)
            end, {
                desc = "Toggle Debug conditional Breakpoint",
            })
        end,
    },
}
