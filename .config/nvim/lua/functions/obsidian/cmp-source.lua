local core = require "functions.core"

local source = {}

function source.new()
    local self = setmetatable({
        obsidian = require "functions.obsidian",
    }, { __index = source })
    return self
end

---@return boolean
function source:is_available()
    return vim.bo.filetype == "markdown"
end

---@return string
function source:get_debug_name()
    return "obsidian"
end

---find notes to perform completion.
---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
function source:complete(params, callback)
    if
        not core.string_has_suffix(
            params.context.cursor_before_line,
            "[[",
            true
        )
    then
        callback {
            items = {},
            isIncomplete = false,
        }
        return
    end

    local files = self.obsidian.vault:list_notes()

    local items = core.array_map(files, function(file)
        ---@type lsp.CompletionItem
        local item = {
            label = file.name,
            kind = 17,
            insertText = file.name .. "]]",
            data = file,
        }
        return item
    end)

    callback {
        items = items,
        isIncomplete = false,
    }
end

---Resolve doc as content of the file.
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:resolve(completion_item, callback)
    local file = completion_item.data

    completion_item.documentation = {
        kind = "markdown",
        value = file:read(),
    }

    callback(completion_item)
end

return source
