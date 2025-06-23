local M = {}

--- Loads a secret using the `pass` command-line tool.
--- @param secret_name string: The name of the secret to load.
--- @return string: The loaded secret.
function M.load_secret(secret_name)
    local handle = io.popen("pass " .. secret_name)
    if not handle then
        error(
            "Failed to load secret '"
                .. secret_name
                .. "'. Error: handle cannot be created"
        )
    end
    local result = handle:read "*a"
    handle:close()
    return result:gsub("\n", "")
end

return M
