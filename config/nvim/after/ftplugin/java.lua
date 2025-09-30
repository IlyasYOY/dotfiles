local Path = require "plenary.path"
local jdtls = require "jdtls"
local core = require "ilyasyoy.functions.core"

local function get_install_path_for(package)
    return vim.fn.expand("$MASON/packages/" .. package)
end

-- loads jdks from sdkman.
---@param version string java version to search for
-- This requires java to be installed using sdkman.
local function get_java_dir(version)
    local sdkman_dir = Path.path.home .. "/.sdkman/candidates/java/"
    local java_dirs = vim.fn.readdir(sdkman_dir, function(file)
        if core.string_has_prefix(file, version, true) then
            return 1
        end
    end)

    local java_dir = java_dirs[1]
    if not java_dir then
        error(string.format("No %s java version was found", version))
    end

    return sdkman_dir .. java_dir
end

local last_java_test_command = nil

local config = {
    name = "jdtls",

    cmd = {
        "jdtls",
        "--jvm-arg=-javaagent:"
        .. get_install_path_for "jdtls"
        .. "/lombok.jar",
    },

    root_dir = vim.fs.root(0, { "gradlew", ".git", "mvnw" }),

    settings = {
        java = {
            home = get_java_dir "21",
            redhat = {
                telemetry = { enabled = false },
            },
            sources = {
                organizeImports = {
                    starThreshold = 9999,
                    staticStarThreshold = 9999,
                },
            },
            codeGeneration = {
                toString = {
                    template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
                },
                hashCodeEquals = {
                    useJava7Objects = true,
                },
                useBlocks = true,
            },
            maven = { downloadSources = true },
            format = {
                settings = {
                    url = core.resolve_relative_to_dotfiles_dir "config/eclipse-my-java-google-style.xml",
                    profile = "GoogleStyle",
                },
            },
            compile = {
                nullAnalysis = {
                    nonnull = {
                        "lombok.NonNull",
                        "javax.annotation.Nonnull",
                        "org.eclipse.jdt.annotation.NonNull",
                        "org.springframework.lang.NonNull",
                    },
                },
            },
            eclipse = { downloadSources = true },
            completion = {
                chain = { enabled = false },
                guessMethodArguments = "off",
                favouriteStaticMembers = {
                    "org.junit.jupiter.api.Assertions.*",
                    "org.junit.jupiter.api.Assumptions.*",
                    "org.mockito.Mockito.*",
                    "java.util.Objects.*",
                },
            },
            configuration = {
                runtimes = {
                    {
                        name = "JavaSE-1.8",
                        path = get_java_dir "8",
                    },
                    {
                        name = "JavaSE-11",
                        path = get_java_dir "11",
                    },
                    {
                        name = "JavaSE-17",
                        path = get_java_dir "17",
                    },
                    {
                        name = "JavaSE-21",
                        path = get_java_dir "21",
                    },
                    {
                        name = "JavaSE-23",
                        path = get_java_dir "23",
                    },
                    {
                        name = "JavaSE-25",
                        path = get_java_dir "25",
                    },
                },
            },
        },
    },

    init_options = {
        bundles = vim.iter({
                core.string_split(
                    vim.fn.glob(
                        get_install_path_for "java-debug-adapter"
                        .. "/extension/server/"
                        .. "com.microsoft.java.debug.plugin-*.jar",
                        1
                    ),
                    "\n"
                ),
                core.string_split(
                    vim.fn.glob(
                        get_install_path_for "java-test"
                        .. "/extension/server/"
                        .. "*.jar",
                        1
                    ),
                    "\n"
                ),
            })
            :flatten()
            :totable(),
    },
}

jdtls.start_or_attach(config)

vim.api.nvim_buf_create_user_command(0, "JavaTestAll", function()
    -- Run all tests in the project
    local cmd = "./gradlew test"
    last_java_test_command = cmd
    vim.cmd.Dispatch { last_java_test_command }
end, {
    desc = "run test for all packages",
})

vim.api.nvim_buf_create_user_command(0, "JavaTestFile", function()
    local cmd = "./gradlew test --tests " .. vim.fn.expand "%:t:r"
    last_java_test_command = cmd
    vim.cmd.Dispatch { last_java_test_command }
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

    local cmd = "./gradlew test --tests " .. vim.fn.expand "%:t:r" .. "." .. test_name
    last_java_test_command = cmd
    vim.cmd.Dispatch { last_java_test_command }
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
    if last_java_test_command then
        vim.cmd.Dispatch { last_java_test_command }
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

vim.keymap.set("n", "<localleader>oi", function()
    jdtls.organize_imports()
end, {
    desc = "organize imports",
    buffer = bufnr,
})
vim.keymap.set("n", "<localleader>oa", function()
    jdtls.organize_imports()
    vim.lsp.buf.format()
end, {
    desc = "organize all",
    buffer = bufnr,
})

vim.keymap.set("v", "<localleader>ev", function()
    jdtls.extract_variable(true)
end, {
    desc = "java extract selected to variable",
    noremap = true,
    buffer = bufnr,
})
vim.keymap.set("n", "<localleader>ev", function()
    jdtls.extract_variable()
end, {
    desc = "java extract variable",
    noremap = true,
    buffer = bufnr,
})

vim.keymap.set("v", "<localleader>eV", function()
    jdtls.extract_variable_all(true)
end, {
    desc = "java extract all selected to variable",
    noremap = true,
    buffer = bufnr,
})
vim.keymap.set("n", "<localleader>eV", function()
    jdtls.extract_variable_all()
end, {
    desc = "java extract all to variable",
    noremap = true,
    buffer = bufnr,
})

vim.keymap.set("n", "<localleader>ec", function()
    jdtls.extract_constant()
end, {
    desc = "java extract constant",
    noremap = true,
    buffer = bufnr,
})
vim.keymap.set("v", "<localleader>ec", function()
    jdtls.extract_constant(true)
end, {
    desc = "java extract selected to constant",
    noremap = true,
    buffer = bufnr,
})

vim.keymap.set("n", "<localleader>em", function()
    jdtls.extract_method()
end, {
    desc = "java extract method",
    noremap = true,
    buffer = bufnr,
})
vim.keymap.set("v", "<localleader>em", function()
    jdtls.extract_method(true)
end, {
    desc = "java extract selected to method",
    noremap = true,
    buffer = bufnr,
})
vim.keymap.set("n", "<localleader>oT", function()
    local plugin = require "jdtls.tests"
    plugin.goto_subjects()
end, {
    desc = "java open test",
    noremap = true,
    buffer = bufnr,
})
vim.keymap.set("n", "<localleader>ct", function()
    local plugin = require "jdtls.tests"
    plugin.generate()
end, {
    desc = "java create test",
    noremap = true,
    buffer = bufnr,
})

vim.keymap.set("n", "<localleader>dm", function()
    jdtls.test_nearest_method()
end, {
    desc = "java debug nearest test method",
    buffer = bufnr,
})
vim.keymap.set("n", "<localleader>dc", function()
    jdtls.test_class()
end, {
    desc = "java debug nearest test class",
    buffer = bufnr,
})
vim.keymap.set(
    "n",
    "<localleader>lr",
    "<cmd>JdtWipeDataAndRestart<CR>",
    { desc = "restart jdtls", buffer = bufnr }
)
