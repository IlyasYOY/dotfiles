local pack = require "ilyasyoy.pack"

pack.on_load("dap_python", function()
    local dap_python = require "dap-python"
    dap_python.setup "uv"
    dap_python.test_runner = "pytest"
end)
