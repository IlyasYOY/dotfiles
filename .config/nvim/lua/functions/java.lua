local core = require "functions.core"

local M = {}

-- Converts block of code with assert* per line to a call to assertAll.
--- @param code_block string
--- @return string
local function wrap_text_with_assert_all(code_block)
    local lines = core.string_split(code_block, "\n")
    local result = "assertAll("
    for number, line in ipairs(lines) do
        line = vim.fn.trim(line)
        if line ~= nil and line ~= "" then
            line = core.string_strip_suffix(line, ";")
            if #lines ~= number then
                line = line .. ","
            end
            result = result .. "\n" .. "  () -> " .. line
        end
    end
    result = core.string_strip_suffix(result, ",")
    result = result .. "\n);\n"
    return result
end

-- applied wrap_text_with_assert_all to the selected lines.
local function wrap_selection_with_assert_all()
    local start_position = vim.fn.getpos "'<"
    local end_position = vim.fn.getpos "'>"
    local buffer_number = vim.api.nvim_get_current_buf()

    if end_position[3] == 2147483647 and start_position[3] == 1 then
        local text = core.get_selected_text()
        local lines = core.string_split(wrap_text_with_assert_all(text), "\n")
        vim.api.nvim_buf_set_lines(
            buffer_number,
            start_position[2] - 1,
            end_position[2],
            false,
            lines
        )
    else
        error "You should use line select (S-v)"
    end
end

return {
    wrap_text_with_assert_all = wrap_text_with_assert_all,
    wrap_selection_with_assert_all = wrap_selection_with_assert_all,
}
