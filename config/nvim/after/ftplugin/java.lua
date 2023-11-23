local Path = require "plenary.path"
local coredor = require "coredor"
local lsp = require "ilyasyoy.functions.lsp"
local jdtls = require "jdtls"
local core = require "ilyasyoy.functions.core"

local function get_install_path_for(package)
    return require("mason-registry").get_package(package):get_install_path()
end

-- loads jdks from sdkman.
---@param version string java version to search for
-- This requires java to be installed using sdkman.
local function get_java_dir(version)
    local sdkman_dir = Path.path.home .. "/.sdkman/candidates/java/"
    local java_dirs = vim.fn.readdir(sdkman_dir, function(file)
        if coredor.string_has_prefix(file, version, true) then
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

local eclipse_format_path = vim.g.custom_eclipse_formatter_path
if not eclipse_format_path then
    eclipse_format_path =
        core.resolve_realative_to_dotfiles_dir "config/eclipse-my-java-google-style.xml"
end

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
            home = get_java_dir "17",
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
                },
            },
        },
    },

    on_attach = function(client, bufnr)
        require("jdtls").setup_dap()

        vim.keymap.set("n", "<leader>oi", function()
            jdtls.organize_imports()
        end, {
            desc = "organize imports",
        })
        vim.keymap.set("n", "<leader>oa", function()
            jdtls.organize_imports()
            vim.lsp.buf.format()
        end, {
            desc = "organize all",
        })

        vim.keymap.set("v", "<leader>jev", function()
            jdtls.extract_variable(true)
        end, {
            desc = "java extract selected to variable",
            noremap = true,
        })
        vim.keymap.set("n", "<leader>jev", function()
            jdtls.extract_variable()
        end, {
            desc = "java extract variable",
            noremap = true,
        })

        vim.keymap.set("v", "<leader>jeV", function()
            jdtls.extract_variable_all(true)
        end, {
            desc = "java extract all selected to variable",
            noremap = true,
        })
        vim.keymap.set("n", "<leader>jeV", function()
            jdtls.extract_variable_all()
        end, {
            desc = "java extract all to variable",
            noremap = true,
        })

        vim.keymap.set("n", "<leader>jec", function()
            jdtls.extract_constant()
        end, {
            desc = "java extract constant",
            noremap = true,
        })
        vim.keymap.set("v", "<leader>jec", function()
            jdtls.extract_constant(true)
        end, {
            desc = "java extract selected to constant",
            noremap = true,
        })

        vim.keymap.set("n", "<leader>jem", function()
            jdtls.extract_method()
        end, {
            desc = "java extract method",
            noremap = true,
        })
        vim.keymap.set("v", "<leader>jem", function()
            jdtls.extract_method(true)
        end, {
            desc = "java extract selected to method",
            noremap = true,
        })
        vim.keymap.set("n", "<leader>oT", function()
            local plugin = require "jdtls.tests"
            plugin.goto_subjects()
        end, {
            desc = "java open test",
            noremap = true,
        })
        vim.keymap.set("n", "<leader>ct", function()
            local plugin = require "jdtls.tests"
            plugin.generate()
        end, {
            desc = "java create test",
            noremap = true,
        })

        vim.keymap.set("n", "<leader>jdm", function()
            jdtls.test_nearest_method()
        end, { desc = "java debug nearest test method" })
        vim.keymap.set("n", "<leader>jdc", function()
            jdtls.test_class()
        end, { desc = "java debug nearest test class" })
        vim.keymap.set("n", "<leader>jr", "<cmd>JdtWipeDataAndRestart<CR>", { desc = "restart jdtls" })

        lsp.on_attach(client, bufnr)
    end,
    capabilities = lsp.get_capabilities(),

    init_options = {
        bundles = vim.tbl_flatten {
            coredor.string_split(
                vim.fn.glob(
                    get_install_path_for "java-debug-adapter"
                        .. "/extension/server/"
                        .. "com.microsoft.java.debug.plugin-*.jar",
                    1
                ),
                "\n"
            ),
            coredor.string_split(
                vim.fn.glob(
                    get_install_path_for "java-test"
                        .. "/extension/server/"
                        .. "*.jar",
                    1
                ),
                "\n"
            ),
        },
    },
}

vim.opt_local.tabstop = vim.g.tabs_for_java or 4
vim.opt_local.softtabstop = vim.g.tabs_for_java or 4
vim.opt_local.shiftwidth = vim.g.tabs_for_java or 4
jdtls.start_or_attach(config)
