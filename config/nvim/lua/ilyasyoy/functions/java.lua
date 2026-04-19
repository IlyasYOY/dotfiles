local core = require "ilyasyoy.functions.core"

local M = {}
local supported_java_runtime_versions = { "8", "11", "17", "21", "23", "25" }
local preferred_java_home_versions = { "21", "17", "11", "8", "23", "25" }

local function get_install_path_for(package)
    return vim.fn.expand("$MASON/packages/" .. package)
end

local function get_java_runtime_name(version)
    if version == "8" then
        return "JavaSE-1.8"
    end

    return "JavaSE-" .. version
end

local function get_installed_java_dirs()
    local Path = require "plenary.path"
    local sdkman_dir = Path.path.home .. "/.sdkman/candidates/java/"
    local java_dirs = vim.fn.readdir(sdkman_dir)
    local installed = {}

    for _, version in ipairs(supported_java_runtime_versions) do
        for _, java_dir in ipairs(java_dirs) do
            if core.string_has_prefix(java_dir, version, true) then
                installed[version] = sdkman_dir .. java_dir
                break
            end
        end
    end

    return installed
end

local function get_preferred_java_home(installed_java_dirs)
    for _, version in ipairs(preferred_java_home_versions) do
        local java_dir = installed_java_dirs[version]
        if java_dir then
            return java_dir
        end
    end
end

local function build_java_runtimes(installed_java_dirs)
    local runtimes = {}

    for _, version in ipairs(supported_java_runtime_versions) do
        local java_dir = installed_java_dirs[version]
        if java_dir then
            table.insert(runtimes, {
                name = get_java_runtime_name(version),
                path = java_dir,
            })
        end
    end

    return runtimes
end

function M.get_jdtls_config()
    local installed_java_dirs = get_installed_java_dirs()
    local java_home = get_preferred_java_home(installed_java_dirs)
    if not java_home then
        vim.notify_once(
            "No supported SDKMAN Java runtimes were found; skipping jdtls setup",
            vim.log.levels.WARN
        )
        return nil
    end

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
                home = java_home,
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
                    runtimes = build_java_runtimes(installed_java_dirs),
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

function M.start_or_attach(jdtls)
    local config = M.get_jdtls_config()
    if not config then
        return false
    end

    jdtls.start_or_attach(config)
    return true
end

return M
