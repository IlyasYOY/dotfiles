local M = {}

--- Set up a test/source file toggle for the current buffer.
---
--- Creates a buffer-local user command and a `<localleader>ot` keymap
--- that toggles between a source file and its corresponding test file
--- (or vice-versa).
---
--- Each rule in `opts.rules` is tried in order.  A rule matches when the
--- current file path contains the `detect` pattern.  When a match is
--- found the path is transformed and opened with `:edit`.
---
--- A rule may specify the transformation in one of two ways:
--- * `gsub_pattern` + `gsub_replacement` — a single `string.gsub` call.
--- * `transform` — a function `(path) -> new_path` for multi-step cases
---   (e.g. Java which swaps both the directory and the class name).
---
--- @class ToggleRule
--- @field detect string                          pattern passed to string.find
--- @field gsub_pattern? string                   pattern for string.gsub
--- @field gsub_replacement? string               replacement for string.gsub
--- @field transform? fun(path: string): string   custom path transform
---
--- @param opts { command: string, rules: ToggleRule[] }
function M.setup(opts)
    vim.api.nvim_buf_create_user_command(0, opts.command, function()
        local cwf = vim.fn.expand "%:."
        for _, rule in ipairs(opts.rules) do
            if string.find(cwf, rule.detect) then
                local target
                if rule.transform then
                    target = rule.transform(cwf)
                else
                    target = string.gsub(
                        cwf,
                        rule.gsub_pattern,
                        rule.gsub_replacement
                    )
                end
                vim.cmd("edit " .. target)
                return
            end
        end
    end, {
        desc = "toggle between test and source code",
    })

    vim.keymap.set("n", "<localleader>ot", "<cmd>" .. opts.command .. "<cr>", {
        desc = "toggle between test and source code",
        buffer = true,
    })
end

return M
