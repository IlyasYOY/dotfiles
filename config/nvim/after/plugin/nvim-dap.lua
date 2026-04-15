local dap = require "dap"

local dapui = require "dapui"
dapui.setup()

require("nvim-dap-virtual-text").setup()

require("dap-go").setup()
local dap_python = require "dap-python"
dap_python.setup "uv"
dap_python.test_runner = "pytest"

vim.keymap.set("n", "<F2>", function()
    dap.terminate()
    dapui.close()
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

dap.listeners.before.attach.dapui_config = function()
    dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
    dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
end
