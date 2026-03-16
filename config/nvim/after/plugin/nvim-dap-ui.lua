local dapui_module = require "dapui"

dapui_module.setup()

local function with_dapui(callback)
    return function()
        return callback(dapui_module)
    end
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
