local core = require("core-functions")

local M = {}

-- code_block is text with assertion per line.
M.wrap_with_assert_all = function(code_block)
    local lines = core.string_split(code_block, "\n")
    local result = "assertAll("
    for number, line in ipairs(lines) do
        line = vim.fn.trim(line)
        if line ~= nil and line ~= "" then
            line = core.remove_tail(line, ";")
            if #lines ~= number then
                line = line .. ","
            end
            result = result .. "\n" .. "  () -> " .. line
        end
    end
    result = core.remove_tail(result, ",")
    result = result .. "\n);\n"
    return result
end

return M
