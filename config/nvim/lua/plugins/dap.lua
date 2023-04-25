return {
    {
        "rcarriga/nvim-dap-ui",
        dependencies = {
            "mfussenegger/nvim-dap",
        },
        config = function()
            local dapui = require "dapui"

            dapui.setup()

            vim.keymap.set("n", "<leader>Du", function()
                dapui.toggle { layout = 2 }
            end, {
                desc = "Toggle Simple Debug ui, I mainly use it to run tests",
            })

            vim.keymap.set("n", "<leader>DU", function()
                dapui.toggle()
            end, {
                desc = "Toggle Full Debug ui",
            })
        end,
    },
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "mfussenegger/nvim-dap-python",
        },
        config = function()
            local dap_python = require "dap-python"
            local dap = require "dap"

            dap_python.setup()

            vim.keymap.set("n", "<F5>", function()
                dap.continue()
            end, { desc = "Continue debugging" })

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

            vim.keymap.set("n", "<F6>", function()
                dap.repl.open()
            end, { desc = "Open REPL" })
        end,
    },
}
