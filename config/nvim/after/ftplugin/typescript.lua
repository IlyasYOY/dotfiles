local function setup_toggle()
    vim.api.nvim_buf_create_user_command(0, "TSToggleTest", function()
        local cwf = vim.fn.expand "%:."
        if string.find(cwf, ".*%.test%.ts$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "(%w+)%.test%.ts$", "%1.ts")
            )
        elseif string.find(cwf, "%.ts$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "(%w+)%.ts$", "%1.test.ts")
            )
        end
    end, {
        desc = "toggle between test and source code",
    })

    vim.keymap.set("n", "<localleader>ot", "<cmd>TSToggleTest<cr>", {
        desc = "toggle between test and source code",
        buffer = true,
    })
end

setup_toggle()
