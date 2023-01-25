local null_ls = require "null-ls"

local function with_root_file(builtin, file)
    return builtin.with {
        condition = function(utils)
            return utils.root_has_file(file)
        end,
    }
end

null_ls.setup {
    debounce = 150,
    save_after_format = false,
    sources = {
        with_root_file(null_ls.builtins.formatting.stylua, "stylua.toml"),
        with_root_file(null_ls.builtins.diagnostics.luacheck, ".luacheckrc"),
        null_ls.builtins.diagnostics.jsonlint,
        null_ls.builtins.diagnostics.yamllint,
    },
}
