local core = require "ilyasyoy.functions.core"

vim.api.nvim_buf_create_user_command(
    0,
    "JavaPMD",
    function()
        vim.cmd.Dispatch {
            "-compiler=make",
            "pmd check --no-cache --dir % -R " .. core.resolve_relative_to_dotfiles_dir "config/pmd.xml",
        }
    end,
    {
        desc = "runs pmd for current buffer",
    }
)

vim.api.nvim_buf_create_user_command(
    0,
    "JavaCheckstyle",
    function()
        vim.cmd.Dispatch {
            "checkstyle % -c " .. core.resolve_relative_to_dotfiles_dir "config/checkstyle.xml",
        }
    end,
    {
        desc = "runs checkstyle for current buffer",
    }
)

vim.api.nvim_buf_create_user_command(0, "JavaTestAll", function()
    -- Run all tests in the project
    local cmd = "./gradlew test"
    vim.g.last_java_test_command = cmd
    vim.cmd.Dispatch { vim.g.last_java_test_command }
end, {
    desc = "run test for all packages",
})

vim.api.nvim_buf_create_user_command(0, "JavaTestFile", function()
    local cmd = "./gradlew test --tests " .. vim.fn.expand "%:t:r"
    vim.g.last_java_test_command = cmd
    vim.cmd.Dispatch { vim.g.last_java_test_command }
end, {
    desc = "run test for a file",
})

---gets test name for the node
---@param node TSNode
---@return string?
local function get_test_name(node)
    if node:type() ~= "method_declaration" then
        return
    end

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

vim.api.nvim_buf_create_user_command(0, "JavaTestFunction", function()
    local cwf = vim.fn.expand "%:."

    if not string.find(cwf, "Test%.java$") then
        vim.notify "Not a test file"
        return
    end

    local test_name = nil
    local node = vim.treesitter.get_node()
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

    local cmd = "./gradlew test --tests "
        .. vim.fn.expand "%:t:r"
        .. "."
        .. test_name
    vim.g.last_java_test_command = cmd
    vim.cmd.Dispatch { vim.g.last_java_test_command }
end, {
    desc = "run test for a function",
})

vim.keymap.set("n", "<localleader>ta", "<cmd>JavaTestAll<cr>", {
    desc = "run test for all packages",
    buffer = true,
})

vim.keymap.set("n", "<localleader>tt", "<cmd>JavaTestFile<cr>", {
    desc = "run test for a file",
    buffer = true,
})

vim.keymap.set("n", "<localleader>tf", "<cmd>JavaTestFunction<cr>", {
    desc = "run test for a function",
    buffer = true,
})

vim.api.nvim_buf_create_user_command(0, "JavaTestLast", function(opts)
    if vim.g.last_java_test_command then
        vim.cmd.Dispatch { vim.g.last_java_test_command }
    else
        vim.notify("No previous Java test command to run", vim.log.levels.WARN)
    end
end, {
    desc = "run the last test command again",
})

vim.keymap.set(
    "n",
    "<localleader>tl",
    "<cmd>JavaTestLast<cr>",
    { desc = "run the last test command again", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "JavaToggleTest", function()
    local cwf = vim.fn.expand "%:."
    local change_to = cwf
    if string.find(cwf, "/main/java/") then
        change_to = string.gsub(change_to, "/main/java/", "/test/java/")
        change_to = string.gsub(change_to, "(%w+)%.java$", "%1Test.java")
        vim.cmd("edit " .. change_to)
    elseif string.find(cwf, "/test/java/") then
        change_to = string.gsub(change_to, "/test/java/", "/main/java/")
        change_to = string.gsub(change_to, "(%w+)Test%.java$", "%1.java")
        vim.cmd("edit " .. change_to)
    end
end, {
    desc = "toggle between test and source code",
})

vim.keymap.set("n", "<localleader>ot", "<cmd>JavaToggleTest<cr>", {
    desc = "toggle between test and source code",
    buffer = true,
})


local jdtls = require "jdtls"

local jdtls_config = require("ilyasyoy.functions.java").get_jdtls_config()
jdtls.start_or_attach(jdtls_config)

vim.keymap.set("n", "<localleader>oi", function()
    jdtls.organize_imports()
end, {
    desc = "organize imports",
    buffer = true,
})
vim.keymap.set("n", "<localleader>oa", function()
    jdtls.organize_imports()
    vim.lsp.buf.format()
end, {
    desc = "organize all",
    buffer = true,
})

vim.keymap.set("v", "<localleader>ev", function()
    jdtls.extract_variable(true)
end, {
    desc = "java extract selected to variable",
    noremap = true,
    buffer = true,
})
vim.keymap.set("n", "<localleader>ev", function()
    jdtls.extract_variable()
end, {
    desc = "java extract variable",
    noremap = true,
    buffer = true,
})

vim.keymap.set("v", "<localleader>eV", function()
    jdtls.extract_variable_all(true)
end, {
    desc = "java extract all selected to variable",
    noremap = true,
    buffer = true,
})
vim.keymap.set("n", "<localleader>eV", function()
    jdtls.extract_variable_all()
end, {
    desc = "java extract all to variable",
    noremap = true,
    buffer = true,
})

vim.keymap.set("n", "<localleader>ec", function()
    jdtls.extract_constant()
end, {
    desc = "java extract constant",
    noremap = true,
    buffer = true,
})
vim.keymap.set("v", "<localleader>ec", function()
    jdtls.extract_constant(true)
end, {
    desc = "java extract selected to constant",
    noremap = true,
    buffer = true,
})

vim.keymap.set("n", "<localleader>em", function()
    jdtls.extract_method()
end, {
    desc = "java extract method",
    noremap = true,
    buffer = true,
})
vim.keymap.set("v", "<localleader>em", function()
    jdtls.extract_method(true)
end, {
    desc = "java extract selected to method",
    noremap = true,
    buffer = true,
})
vim.keymap.set("n", "<localleader>oT", function()
    local plugin = require "jdtls.tests"
    plugin.goto_subjects()
end, {
    desc = "java open test",
    noremap = true,
    buffer = true,
})
vim.keymap.set("n", "<localleader>ct", function()
    local plugin = require "jdtls.tests"
    plugin.generate()
end, {
    desc = "java create test",
    noremap = true,
    buffer = true,
})

vim.keymap.set("n", "<localleader>dm", function()
    jdtls.test_nearest_method()
end, {
    desc = "java debug nearest test method",
    buffer = true,
})
vim.keymap.set("n", "<localleader>dc", function()
    jdtls.test_class()
end, {
    desc = "java debug nearest test class",
    buffer = true,
})
vim.keymap.set(
    "n",
    "<localleader>lr",
    "<cmd>JdtWipeDataAndRestart<CR>",
    { desc = "restart jdtls", buffer = true }
)
