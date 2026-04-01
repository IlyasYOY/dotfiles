local M = {}

--- Loads a secret using the `pass` command-line tool.
--- @param secret_name string: The name of the secret to load.
--- @return string: The loaded secret.
function M.load_secret(secret_name)
    local result = vim.system({ "pass", secret_name }, { text = true }):wait()
    if result.code ~= 0 then
        error(
            "Failed to load secret '"
                .. secret_name
                .. "'. Error: "
                .. (result.stderr or "unknown")
        )
    end
    return (result.stdout or ""):gsub("\n", "")
end

return M
