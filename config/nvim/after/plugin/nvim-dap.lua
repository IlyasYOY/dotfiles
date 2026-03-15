local pack = require "ilyasyoy.pack"

pack.on_load("dap", function()
    require("nvim-dap-virtual-text").setup()
end)

local function with_dap(callback)
    return pack.wrap("dap", function()
        return callback(require "dap")
    end)
end

vim.keymap.set(
    "n",
    "<F2>",
    with_dap(function(dap)
        dap.terminate()
    end),
    { desc = "Stop debugging" }
)

vim.keymap.set(
    "n",
    "<F5>",
    with_dap(function(dap)
        dap.continue()
    end),
    { desc = "Continue debugging" }
)

vim.keymap.set(
    "n",
    "<F6>",
    with_dap(function(dap)
        dap.repl.open()
    end),
    { desc = "Open REPL" }
)

vim.keymap.set(
    "n",
    "<F7>",
    with_dap(function(dap)
        dap.run_to_cursor()
    end),
    { desc = "Run debugging to cursor" }
)

vim.keymap.set(
    "n",
    "<F10>",
    with_dap(function(dap)
        dap.step_over()
    end),
    { desc = "Step over" }
)

vim.keymap.set(
    "n",
    "<F11>",
    with_dap(function(dap)
        dap.step_into()
    end),
    { desc = "Step into" }
)

vim.keymap.set(
    "n",
    "<F12>",
    with_dap(function(dap)
        dap.step_out()
    end),
    { desc = "Step out" }
)

vim.keymap.set(
    "n",
    "<leader>Db",
    with_dap(function(dap)
        dap.toggle_breakpoint()
    end),
    {
        desc = "Toggle Debug breakpoint",
    }
)

vim.keymap.set(
    "n",
    "<leader>DB",
    with_dap(function(dap)
        local condition = vim.fn.input "Breakpoint condition: "
        dap.set_breakpoint(condition)
    end),
    {
        desc = "Toggle Debug conditional Breakpoint",
    }
)
