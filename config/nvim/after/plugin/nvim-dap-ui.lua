local pack = require "ilyasyoy.pack"

pack.on_load("dap", function()
    require("dapui").setup()
end)

local function with_dapui(callback)
    return pack.wrap("dap", function()
        return callback(require "dapui")
    end)
end

vim.keymap.set(
    "n",
    "<leader>Du",
    with_dapui(function(dapui)
        dapui.toggle { layout = 2 }
    end),
    {
        desc = "Toggle Simple Debug ui, I mainly use it to run tests",
    }
)

vim.keymap.set(
    "n",
    "<leader>DU",
    with_dapui(function(dapui)
        dapui.toggle()
    end),
    {
        desc = "Toggle Full Debug ui",
    }
)
