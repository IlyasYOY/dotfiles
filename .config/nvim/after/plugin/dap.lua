local dapui = require "dapui"
local dap_python = require "dap-python"
local dap = require "dap"

dapui.setup()
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
    desc = "Toggle [D]ebug [b]reakpoint",
})

vim.keymap.set("n", "<leader>DB", function()
    local condition = vim.fn.input "Breakpoint condition: "
    dap.set_breakpoint(condition)
end, {
    desc = "Toggle [D]ebug conditional [B]reakpoint",
})

vim.keymap.set("n", "<F6>", function()
    dap.repl.open()
end, { desc = "Open REPL" })

vim.keymap.set("n", "<leader>Du", function()
    dapui.toggle {}
end, {
    desc = "Toggle [D]ebug [u]i",
})
