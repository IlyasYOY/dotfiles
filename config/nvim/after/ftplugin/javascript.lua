local test_helpers = require "ilyasyoy.functions.test"
local toggle_helpers = require "ilyasyoy.functions.toggle_test"

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

local function find_js_test_name()
    local node = vim.treesitter.get_node()
    while node do
        local name = get_test_name(node)
        if name then
            return name
        end
        node = node:parent()
    end
end

test_helpers.setup {
    prefix = "JS",
    var_name = "last_js_test_command",
    compiler = "jest",
    lang = "JavaScript",
    all = {
        cmd = "npx jest .",
        desc = "run test for all packages",
    },
    package = {
        cmd_fn = function()
            return "npx jest " .. vim.fn.expand "%:.:h"
        end,
        desc = "run test for a package",
    },
    file = {
        cmd_fn = function()
            return "npx jest " .. vim.fn.expand "%"
        end,
        desc = "run test for a file",
    },
    current = {
        test_file_pattern = "test%.js$",
        get_name_fn = find_js_test_name,
        cmd_fn = function(name)
            return "npx jest -t '" .. name .. "'"
        end,
        desc = "run test for a function",
    },
}

toggle_helpers.setup {
    command = "JSToggleTest",
    rules = {
        {
            detect = ".*%.test%.js$",
            gsub_pattern = "(%w+)%.test%.js$",
            gsub_replacement = "%1.js",
        },
        {
            detect = "%.js$",
            gsub_pattern = "(%w+)%.js$",
            gsub_replacement = "%1.test.js",
        },
    },
}
