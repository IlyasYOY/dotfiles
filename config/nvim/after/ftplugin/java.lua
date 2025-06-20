local Path = require "plenary.path"
local lsp = require "ilyasyoy.functions.lsp"
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

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:gs?/?-?:s?~-??")
local workspace_dir = Path.path.home
    .. "/Projects/eclipse-java/"
    .. project_name

local eclipse_format_path =
    core.resolve_relative_to_dotfiles_dir "config/eclipse-my-java-google-style.xml"

local config = {
    cmd = {
        "jdtls",
        "-data",
        workspace_dir,
        "--jvm-arg=-XX:+UseParallelGC",
        "--jvm-arg=-XX:GCTimeRatio=4",
        "--jvm-arg=-XX:AdaptiveSizePolicyWeight=90",
        "--jvm-arg=-Dsun.zip.disableMemoryMapping=true",
        "--jvm-arg=-Xmx1500m",
        "--jvm-arg=-Xms700m",
        "--jvm-arg=-Xlog:disable",
        "--jvm-arg=-javaagent:"
        .. get_install_path_for "jdtls"
        .. "/lombok.jar",
    },

    root_dir = require("jdtls.setup").find_root { "mvnw", "gradlew" },

    settings = {
        java = {
            home = get_java_dir "23",
            redhat = {
                telemetry = { enabled = false },
            },
            extendedClientCapabilities = jdtls.extendedClientCapabilities,
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
                    url = eclipse_format_path,
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
                -- doesn't seem to work now with cmp.
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
                },
            },
        },
    },

    on_attach = function(client, bufnr)
        require("jdtls").setup_dap()

        vim.keymap.set("n", "<localleader>oi", function()
            jdtls.organize_imports()
        end, {
            desc = "organize imports",
        })
        vim.keymap.set("n", "<localleader>oa", function()
            jdtls.organize_imports()
            vim.lsp.buf.format()
        end, {
            desc = "organize all",
        })

        vim.keymap.set("v", "<localleader>ev", function()
            jdtls.extract_variable(true)
        end, {
            desc = "java extract selected to variable",
            noremap = true,
        })
        vim.keymap.set("n", "<localleader>ev", function()
            jdtls.extract_variable()
        end, {
            desc = "java extract variable",
            noremap = true,
        })

        vim.keymap.set("v", "<localleader>eV", function()
            jdtls.extract_variable_all(true)
        end, {
            desc = "java extract all selected to variable",
            noremap = true,
        })
        vim.keymap.set("n", "<localleader>eV", function()
            jdtls.extract_variable_all()
        end, {
            desc = "java extract all to variable",
            noremap = true,
        })

        vim.keymap.set("n", "<localleader>ec", function()
            jdtls.extract_constant()
        end, {
            desc = "java extract constant",
            noremap = true,
        })
        vim.keymap.set("v", "<localleader>ec", function()
            jdtls.extract_constant(true)
        end, {
            desc = "java extract selected to constant",
            noremap = true,
        })

        vim.keymap.set("n", "<localleader>em", function()
            jdtls.extract_method()
        end, {
            desc = "java extract method",
            noremap = true,
        })
        vim.keymap.set("v", "<localleader>em", function()
            jdtls.extract_method(true)
        end, {
            desc = "java extract selected to method",
            noremap = true,
        })
        vim.keymap.set("n", "<localleader>oT", function()
            local plugin = require "jdtls.tests"
            plugin.goto_subjects()
        end, {
            desc = "java open test",
            noremap = true,
        })
        vim.keymap.set("n", "<localleader>ct", function()
            local plugin = require "jdtls.tests"
            plugin.generate()
        end, {
            desc = "java create test",
            noremap = true,
        })

        vim.keymap.set("n", "<localleader>dm", function()
            jdtls.test_nearest_method()
        end, { desc = "java debug nearest test method" })
        vim.keymap.set("n", "<localleader>dc", function()
            jdtls.test_class()
        end, { desc = "java debug nearest test class" })
        vim.keymap.set(
            "n",
            "<localleader>lr",
            "<cmd>JdtWipeDataAndRestart<CR>",
            { desc = "restart jdtls" }
        )

        lsp.on_attach(client, bufnr)
    end,
    capabilities = lsp.get_capabilities(),

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

vim.keymap.set("n", "<localleader>ta", function()
    vim.cmd.Dispatch { "./gradlew test" }
end, { desc = "run test for all packages", buffer = true })

vim.keymap.set("n", "<localleader>tt", function()
    vim.cmd.Dispatch {
        "./gradlew test --tests " .. vim.fn.expand "%:t:r",
    }
end, { desc = "run test for a file", buffer = true })

vim.keymap.set("n", "<localleader>tf", function()
    local cwf = vim.fn.expand "%:."
    local bufnr = vim.api.nvim_get_current_buf()

    if string.find(cwf, "Test.java$") then
        local function_name = nil
        local node_under_cursor = vim.treesitter.get_node()
        local curr_node = node_under_cursor
        while curr_node do
            -- TODO: Here we can check if we have Test annotation but I think it's overcomplication
            if curr_node:type() == "method_declaration" then
                local name_node = curr_node:field("name")[1]
                if name_node then
                    function_name =
                        vim.treesitter.get_node_text(name_node, bufnr)
                    break
                end
            end
            curr_node = curr_node:parent()
        end
        if not function_name then
            vim.notify "test function was not found"
        else
            vim.cmd.Dispatch {
                "./gradlew test --tests "
                .. vim.fn.expand "%:t:r"
                .. "."
                .. function_name,
            }
        end
    end
end, { desc = "run test for a function", buffer = true })

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
