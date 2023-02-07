local Path = require "plenary.path"
local coredor = require "coredor"
local lsp = require "ilyasyoy.functions.lsp"
local jdtls = require "jdtls"

local function get_install_path_for(package)
    return require("mason-registry").get_package(package):get_install_path()
end

-- loads jdks from sdkman.
---@param version string java version to search for
-- NOTE: This requires java to be installed using sdkman.
local function get_java_dir(version)
    local sdkman_dir = Path.path.home .. "/.sdkman/candidates/java/"
    local java_dirs = vim.fn.readdir(sdkman_dir, function(file)
        if coredor.string_has_prefix(file, version) then
            return 1
        end
    end)

    local java_dir = java_dirs[1]
    if not java_dir then
        error(string.format("No %s java version was found", version))
    end

    return sdkman_dir .. java_dir
end

--NOTE:This is base dir for Eclipse project files.
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = Path.path.home
    .. "/Projects/eclipse-java/"
    .. project_name

local config = {
    cmd = {
        "jdtls",
        "-data",
        workspace_dir,
        -- NOTE: Lombok JAR must be in home dir.
        "--jvm-arg=-javaagent:"
            .. get_install_path_for "jdtls"
            .. "/lombok.jar",
    },

    root_dir = require("jdtls.setup").find_root { "mvnw", "gradlew" },

    settings = {
        java = {
            eclipse = {
                downloadSources = true,
            },
            completion = {
                favouriteStaticMembers = {
                    "java.util.Objects.*",
                    "org.junit.jupiter.api.Assertions.*",
                    "org.junit.jupiter.api.Assumptions.*",
                    "org.mockito.Mockito.*",
                },
                guessMethodArguments = false,
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
        --WARN: I don't know why, but this doesn't work.
        -- see https://github.com/mfussenegger/nvim-jdtls/discussions/412#discussioncomment-4873025
        require("jdtls").setup_dap()
        vim.keymap.set("n", "<leader>oi", function()
            jdtls.organize_imports()
        end, {
            desc = "[o]rganize [i]mports",
        })
        vim.keymap.set("n", "<leader>oa", function()
            jdtls.organize_imports()
            vim.lsp.buf.format()
        end, {
            desc = "[o]rganize [a]ll",
        })
        vim.keymap.set({ "n", "v" }, "<leader>jev", function()
            jdtls.extract_variable()
        end, {
            desc = "java [e]xtract [v]ariable",
        })
        vim.keymap.set({ "n", "v" }, "<leader>jec", function()
            jdtls.extract_constant()
        end, {
            desc = "java [e]xtract [c]onstant",
        })
        vim.keymap.set({ "n", "v", "s" }, "<leader>jem", function()
            jdtls.extract_method()
        end, {
            desc = "java [e]xtract [m]ethod",
        })
        vim.cmd [[ command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>) ]]
        vim.cmd [[ command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_set_runtime JdtSetRuntime lua require('jdtls').set_runtime(<f-args>) ]]
        vim.cmd [[ command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config() ]]
        vim.cmd [[ command! -buffer JdtBytecode lua require('jdtls').javap() ]]
        -- They don't work:
        -- vim.cmd [[ command! -buffer JdtJol lua require('jdtls').jol() ]]
        -- vim.cmd [[ command! -buffer JdtJshell lua require('jdtls').jshell() ]]
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

jdtls.start_or_attach(config)
