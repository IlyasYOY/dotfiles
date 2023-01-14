local Path = require "plenary.path"
local core = require "ilyasyoy.functions.core"
local lsp = require "ilyasyoy.functions.lsp"
local lspconfig = require "lspconfig"

-- loads jdks from sdkman.
-- TODO: fully refactor to plenary
--
---@param version string java version to search for
local function get_java_dir(version)
    local sdkman_dir = Path.path.home .. "/.sdkman/candidates/java/"
    local java_dirs = vim.fn.readdir(sdkman_dir, function(file)
        if core.string_has_prefix(file, version) then
            return 1
        end
    end)

    local java_dir = java_dirs[1]
    if not java_dir then
        error(string.format("No %s java version was found", version))
    end

    return sdkman_dir .. java_dir
end

lspconfig.jdtls.setup {
    on_attach = lsp.on_attach,
    capabilities = lsp.get_capabilities(),
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
                    { name = "JavaSE-1.8", path = get_java_dir "8" },
                    { name = "JavaSE-11", path = get_java_dir "11" },
                    { name = "JavaSE-17", path = get_java_dir "17" },
                },
            },
        },
    },
}
