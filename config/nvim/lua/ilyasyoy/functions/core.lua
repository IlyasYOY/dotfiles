local Path = require "plenary.path"

local M = {}

local function resolve_dotfiles_plenary_path()
    local path_from_env = vim.fn.environ().ILYASYOY_DOTFILES_DIR
    return Path:new(path_from_env)
end

function M.get_dotfiles_dir()
    return resolve_dotfiles_plenary_path():expand()
end

function M.resolve_realative_to_dotfiles_dir(path)
    local plenary_path = resolve_dotfiles_plenary_path()
    return (plenary_path / path):expand()
end

return M
