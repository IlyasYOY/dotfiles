vim.bo.formatprg = "stylua -"

local function setup_toggle()
    vim.api.nvim_buf_create_user_command(0, "LuaToggleTest", function()
        local cwf = vim.fn.expand "%:."
        if string.find(cwf, "_spec%.lua$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "(%w+)_spec%.lua$", "%1.lua")
            )
        elseif string.find(cwf, "%.lua$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "(%w+)%.lua$", "%1_spec.lua")
            )
        end
        return false
    end, {
        desc = "toggle between test and source code",
    })

    vim.keymap.set("n", "<localleader>ot", "<cmd>LuaToggleTest<cr>", {
        desc = "toggle between test and source code",
        buffer = true,
    })
end

setup_toggle()
