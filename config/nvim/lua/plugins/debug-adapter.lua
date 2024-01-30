return {
    {
        "rcarriga/nvim-dap-ui",
        dependencies = {
            "mfussenegger/nvim-dap",
        },
        keys = {
            "<leader>Du",
            "<leader>DU",
        },
        config = function()
            print "dap"
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
        lazy = true,
        config = function()
            local dap = require "dap"

            vim.keymap.set("n", "<F2>", function()
                dap.close()
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
    {
        "mfussenegger/nvim-dap-python",
        dependencies = {
            "mfussenegger/nvim-dap",
        },
        ft = "python",
        config = function()
            require("dap-python").setup()
        end,
    },
    {
        "leoluz/nvim-dap-go",
        dependencies = {
            "mfussenegger/nvim-dap",
        },
        ft = "go",
        config = function()
            require("dap-go").setup()

            vim.keymap.set("n", "<leader>gdm", function()
                require("dap-go").debug_test()
            end)
        end,
    },
}
