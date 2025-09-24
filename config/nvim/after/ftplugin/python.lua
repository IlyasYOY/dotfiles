vim.bo.formatoptions = vim.bo.formatoptions .. "ro/"

vim.api.nvim_buf_create_user_command(0, "PythonTestAll", function(opts)
    vim.cmd.Dispatch {
        "-compiler=pytest",
        "pytest",
    }
end, {
    desc = "run test for all packages",
})

vim.keymap.set(
    "n",
    "<localleader>ta",
    "<cmd>PythonTestAll<cr>",
    { desc = "run test for all packages", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "PythonTestPackage", function(opts)
    vim.cmd.Dispatch {
        "-compiler=pytest",
        "pytest " .. vim.fn.expand "%:p:h",
    }
end, {
    desc = "run test for a package",
})

vim.keymap.set(
    "n",
    "<localleader>tp",
    "<cmd>PythonTestPackage<cr>",
    { desc = "run test for a package", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "PythonTestFile", function(opts)
    local cwf = vim.fn.expand "%:."
    vim.cmd.Dispatch {
        "-compiler=pytest",
        "pytest " .. cwf,
    }
end, {
    desc = "run test for a file",
})

vim.keymap.set(
    "n",
    "<localleader>tt",
    "<cmd>PythonTestFile<cr>",
    { desc = "run test for a file", buffer = true }
)

---@param node TSNode
---@return string?
local function get_test_name(node)
    if node:type() == "function_definition" then
        local name_nodes = node:field "name"
        if #name_nodes == 0 then
            return
        end

        local name_node = name_nodes[1]
        if not name_node then
            return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        return vim.treesitter.get_node_text(name_node, bufnr)
    end
end

vim.api.nvim_buf_create_user_command(0, "PythonTestFunction", function()
    local cwf = vim.fn.expand "%:."

    if not string.find(cwf, "test_.*%.py$") then
        vim.notify "Not a test file"
        return
    end

    local test_name = nil
    local node = vim.treesitter.get_node() -- node under the cursor

    while node do
        test_name = get_test_name(node)
        if test_name then
            break
        end
        node = node:parent()
    end

    if not test_name then
        vim.notify "Test function was not found"
        return
    end

    vim.cmd.Dispatch {
        "-compiler=pytest",
        "pytest " .. cwf .. "::" .. test_name,
    }
end, {
    desc = "run test for a function",
})

vim.keymap.set("n", "<localleader>tf", "<cmd>PythonTestFunction<cr>", {
    desc = "run test for a function",
    buffer = true,
})

vim.api.nvim_buf_create_user_command(0, "PythonToggleTest", function()
    local cwf = vim.fn.expand "%:."
    if string.find(cwf, "test_[%w_]+%.py$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "test_([%w_]+)%.py$", "%1.py"))
    elseif string.find(cwf, "[%w_]+%.py$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "([%w_]+)%.py$", "test_%1.py"))
    end
end, {
    desc = "toggle between test and source code",
})

vim.keymap.set("n", "<localleader>ot", "<cmd>PythonToggleTest<cr>", {
    desc = "toggle between test and source code",
    buffer = true,
})
