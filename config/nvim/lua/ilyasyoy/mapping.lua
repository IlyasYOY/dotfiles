local core = require "coredor"

vim.keymap.set("n", "<leader>sc", function()
    vim.opt_local.spell = not (vim.opt_local.spell:get())
    vim.notify("spell: " .. tostring(vim.o.spell))
end, { desc = "Toggle spell check" })

vim.keymap.set(
    "t",
    "<Esc>",
    "<C-\\><C-n>",
    { desc = "Use Escape to go from terminal to Normal mode" }
)

-- Dev things

vim.keymap.set(
    "n",
    "<leader><leader>S",
    "<cmd>source %<CR>",
    { desc = "source current file" }
)

vim.keymap.set(
    "n",
    "<leader><leader>s",
    "<cmd>mksession!<CR>",
    { desc = "create session file" }
)

local function process_lua()
    local cwf = core.current_working_file()
    if string.find(cwf, "_spec%.lua$") then
        vim.fn.execute(
            "edit " .. string.gsub(cwf, "(%w+)_spec%.lua$", "%1.lua")
        )
        return true
    elseif string.find(cwf, "%.lua$") then
        vim.fn.execute(
            "edit " .. string.gsub(cwf, "(%w+)%.lua$", "%1_spec.lua")
        )
        return true
    end
    return false
end

local function process_java()
    local cwf = core.current_working_file()
    local change_to = cwf
    if string.find(cwf, "/main/java/") then
        change_to = string.gsub(change_to, "/main/java/", "/test/java/")
        change_to = string.gsub(change_to, "(%w+)%.java$", "%1Test.java")
        vim.cmd("edit " .. change_to)
        return true
    elseif string.find(cwf, "/test/java/") then
        change_to = string.gsub(change_to, "/test/java/", "/main/java/")
        change_to = string.gsub(change_to, "(%w+)Test%.java$", "%1.java")
        vim.cmd("edit " .. change_to)
        return true
    end
    return false
end

local function process_python()
    local cwf = core.current_working_file()
    if string.find(cwf, "_test%.py$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "(%w+)_test%.py$", "%1.py"))
        return true
    elseif string.find(cwf, "%.py$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "(%w+)%.py$", "%1_test.py"))
        return true
    end
    return false
end

local function process_go()
    local cwf = core.current_working_file()
    if string.find(cwf, "_test%.go$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "(%w+)_test%.go$", "%1.go"))
        return true
    elseif string.find(cwf, "%.go$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "(%w+)%.go$", "%1_test.go"))
        return true
    end
    return false
end

vim.keymap.set("n", "<leader>ot", function()
    local filetype = vim.bo.filetype

    if filetype == "lua" then
        if process_lua() then
            return
        end
    end
    if filetype == "go" then
        if process_go() then
            return
        end
    end
    if filetype == "java" then
        if process_java() then
            return
        end
    end
    if filetype == "python" then
        if process_python() then
            return
        end
    end

    vim.notify "No test file was found to switch to"
end, {
    desc = "go to test",
})
