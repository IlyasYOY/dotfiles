local coredor = require "coredor"
local Path = require "plenary.path"
local lsp = require "ilyasyoy.functions.lsp"

-- loads jdks from sdkman.
-- NOTE: This requires java to be installed using sdkman.
--
---@param version string java version to search for
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

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = Path.path.home
    --NOTE:This is base dir for Ecllipse project files.
    .. "/Projects/eclipse-java/"
    .. project_name

local config = {
    cmd = {
        "jdtls",
        "-data",
        workspace_dir,
        -- NOTE: Lombok JAR must be in home dir.
        "--jvm-arg=-javaagent:"
            .. Path.path.home
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

    on_attach = lsp.on_attach,
    capabilities = lsp.get_capabilities(),
}

require("jdtls").start_or_attach(config)
