local pickers = require "telescope.pickers"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local builtin = require "telescope.builtin"

local M = {}

-- helper to perform telescope routine
--- @param title string name for the widow
--- @param items Array<string> items to search through
--- @param callback fun(Array) functions to be applied to the resulting string
--- @param opts table additional options for telescope
--- @param entry_maker fun(table): table
function M.find_through_items(title, items, callback, entry_maker, opts)
    opts = opts or {}

    pickers
        .new(opts, {
            prompt_title = title,
            previewer = conf.file_previewer(opts),
            finder = finders.new_table {
                results = items,
                entry_maker = entry_maker,
            },
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    callback(selection)
                end)
                return true
            end,
        })
        :find()
end

function M.grep_files(title, path, type_filter)
    if type_filter == nil then
        type_filter = "md"
    end

    return builtin.live_grep {
        cwd = path,
        prompt_title = title,
        type_filter = type_filter
    }
end

function M.find_files(title, path)
    return builtin.find_files {
        cwd = path,
        prompt_title = title,
    }
end

return M
