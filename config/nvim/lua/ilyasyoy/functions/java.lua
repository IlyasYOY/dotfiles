local core = require "ilyasyoy.functions.core"

local M = {}

local function get_install_path_for(package)
    return vim.fn.expand("$MASON/packages/" .. package)
end

-- loads jdks from sdkman.
---@param version string java version to search for
-- This requires java to be installed using sdkman.
local function get_java_dir(version)
    local Path = require "plenary.path"

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

function M.get_jdtls_config()
    return {
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
end

return M
