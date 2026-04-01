local M = {}

--- Walk up the AST from the cursor and return the first value produced by
--- the predicate.
---
--- @param predicate fun(node: TSNode): any?
--- @return any?
function M.find_enclosing_node(predicate)
    local node = vim.treesitter.get_node()
    while node do
        local result = predicate(node)
        if result then
            return result
        end
        node = node:parent()
    end
    return nil
end

--- Extract the text of a named field from a treesitter node.
---
--- @param node TSNode
--- @param field_name string
--- @return string?
function M.get_node_field_text(node, field_name)
    local fields = node:field(field_name)
    if #fields == 0 then
        return nil
    end
    local field = fields[1]
    if not field then
        return nil
    end
    return vim.treesitter.get_node_text(field, vim.api.nvim_get_current_buf())
end

--- Return the name of the enclosing node of a given type.
---
--- Convenience wrapper that combines `find_enclosing_node` and
--- `get_node_field_text` for the common case of extracting the "name"
--- field from the nearest ancestor of a specific type.
---
--- @param node_type string  treesitter node type (e.g. "function_declaration")
--- @return string?
function M.get_enclosing_name(node_type)
    return M.find_enclosing_node(function(node)
        if node:type() == node_type then
            return M.get_node_field_text(node, "name")
        end
    end)
end

return M
