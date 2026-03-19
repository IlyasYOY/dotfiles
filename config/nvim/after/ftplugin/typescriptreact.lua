local function setup_toggle()
    vim.api.nvim_buf_create_user_command(0, "TSXToggleTest", function()
        local cwf = vim.fn.expand "%:."
        if string.find(cwf, ".*%.test%.tsx$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "(%w+)%.test%.tsx$", "%1.tsx")
            )
        elseif string.find(cwf, "%.tsx$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "(%w+)%.tsx$", "%1.test.tsx")
            )
        end
    end, {
        desc = "toggle between test and source code",
    })

    vim.keymap.set("n", "<localleader>ot", "<cmd>TSXToggleTest<cr>", {
        desc = "toggle between test and source code",
        buffer = true,
    })
end

setup_toggle()
