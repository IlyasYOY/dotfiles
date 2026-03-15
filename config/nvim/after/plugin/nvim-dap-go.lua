local pack = require "ilyasyoy.pack"

pack.on_load("dap_go", function()
    require("dap-go").setup()
end)
