vim.api.nvim_buf_create_user_command(0, "JSTestAll", function()
    vim.cmd.Dispatch {
        "-compiler=jest",
        "npx jest .",
    }
end, {
    desc = "run test for all packages",
})

vim.api.nvim_buf_create_user_command(0, "JSTestPackage", function()
    vim.cmd.Dispatch {
        "-compiler=jest",
        "npx jest " .. vim.fn.expand "%:.:h",
    }
end, {
    desc = "run test for a file",
})

vim.api.nvim_buf_create_user_command(0, "JSTestFile", function()
    vim.cmd.Dispatch {
        "-compiler=jest",
        "npx jest " .. vim.fn.expand "%",
    }
end, {
    desc = "run test for a file",
})

---@param node TSNode
---@return string?
local function get_test_name(node)
    if node:type() ~= "call_expression" then
        return
    end

    local func_node = node:field("function")[1]
    if not func_node then
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local func_name = vim.treesitter.get_node_text(func_node, bufnr)
    if func_name ~= "test" and func_name ~= "it" then
        return
    end

    local args = node:field "arguments"
    if not args or #args == 0 then
        return
    end

    local arguments_node = args[1]
    if arguments_node:named_child_count() == 0 then
        return
    end

    local name_node = arguments_node:named_child(0)
    if not name_node or name_node:type() ~= "string" then
        return
    end

    local raw_test_name = vim.treesitter.get_node_text(name_node, bufnr)
    local test_name = raw_test_name:gsub("^[\"']", ""):gsub("[\"']$", "")
    return test_name
end

vim.api.nvim_buf_create_user_command(0, "JSTestFunction", function()
    local cwf = vim.fn.expand "%:."

    if not string.find(cwf, "test%.js$") then
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
        "-compiler=jest",
        "npx jest -t '" .. test_name .. "'",
    }
end, {
    desc = "run test for a function",
})

vim.keymap.set("n", "<localleader>ta", "<cmd>JSTestAll<cr>", {
    desc = "run test for all packages",
    buffer = true,
})

vim.keymap.set("n", "<localleader>tp", "<cmd>JSTestPackage<cr>", {
    desc = "run test for a package",
    buffer = true,
})

vim.keymap.set("n", "<localleader>tt", "<cmd>JSTestFile<cr>", {
    desc = "run test for a file",
    buffer = true,
})

vim.keymap.set("n", "<localleader>tf", "<cmd>JSTestFunction<cr>", {
    desc = "run test for a function",
    buffer = true,
})

vim.api.nvim_buf_create_user_command(0, "JSToggleTest", function()
    local cwf = vim.fn.expand "%:."
    if string.find(cwf, ".*%.test.js$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "(%w+)%.test.js$", "%1.js"))
    elseif string.find(cwf, "%.js$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "(%w+)%.js$", "%1.test.js"))
    end
end, {
    desc = "toggle between test and source code",
})

vim.keymap.set("n", "<localleader>ot", "<cmd>JSToggleTest<cr>", {
    desc = "toggle between test and source code",
    buffer = true,
})
