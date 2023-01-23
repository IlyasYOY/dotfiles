local core = require "coredor"

vim.keymap.set("n", "<leader>sc", function()
    vim.opt_local.spell = not (vim.opt_local.spell:get())
    vim.notify("spell: " .. tostring(vim.o.spell))
end, { desc = "Toggle [s]pell [c]heck" })

vim.keymap.set(
    "t",
    "<Esc>",
    "<C-\\><C-n>",
    { desc = "Use Escape to go from terminal to Normal mode" }
)

-- Dev things

vim.keymap.set("n", "<leader><leader>s", "<cmd>source %<CR>")

vim.keymap.set("n", "<leader><leader>t", "<Plug>PlenaryTestFile", {
    desc = "Runs Plenary [t]ests for file",
})

vim.keymap.set(
    "n",
    "<leader><leader>T",
    -- TODO: Default is {sequential=false}.
    -- I have helpers for test dirs which cause problems in concurrent env.
    "<cmd>PlenaryBustedDirectory . {sequential=true}<CR>",
    {
        desc = "Runs Plenary [T]ests in cwd",
    }
)

vim.keymap.set("n", "<leader>gt", function()
    local filetype = vim.bo.filetype
    local cwf = core.current_working_file()

    if filetype == "lua" then
        if string.find(cwf, "_spec%.lua$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "(%w+)_spec%.lua$", "%1.lua")
            )
            return
        elseif string.find(cwf, "%.lua$") then
            vim.fn.execute(
                "edit " .. string.gsub(cwf, "(%w+)%.lua$", "%1_spec.lua")
            )
            return
        end
    end

    if filetype == "java" then
        local change_to = cwf
        if string.find(cwf, "/main/java/") then
            change_to = string.gsub(change_to, "/main/java/", "/test/java/")
            change_to = string.gsub(change_to, "(%w+)%.java$", "%1Test.java")
            vim.cmd("edit " .. change_to)
            return
        elseif string.find(cwf, "/test/java/") then
            change_to = string.gsub(change_to, "/test/java/", "/main/java/")
            change_to = string.gsub(change_to, "(%w+)Test%.java$", "%1.java")
            vim.cmd("edit " .. change_to)
            return
        end
    end

    vim.notify "No test file was found to switch to"
end)
