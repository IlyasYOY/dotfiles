local qfstore = require "ilyasyoy.functions.qfstore"

local function default_name(args)
    local name = args.fargs and args.fargs[1]
    if name and name ~= "" then
        return name
    end
    return os.date "%Y%m%d-%H%M%S"
end

local function store_with_collision_check(name, loclist)
    if qfstore.exists(name) then
        vim.ui.select({
            { label = "Overwrite", action = true },
            { label = "Cancel", action = false },
        }, {
            prompt = "qfstore: '" .. name .. "' already exists. Overwrite?",
            format_item = function(c)
                return c.label
            end,
        }, function(choice)
            if choice and choice.action then
                local ok, res = qfstore.store {
                    name = name,
                    loclist = loclist,
                }
                if ok then
                    vim.notify(
                        string.format(
                            "qfstore: stored %d items as '%s'",
                            res,
                            name
                        )
                    )
                else
                    vim.notify("qfstore: " .. res, vim.log.levels.ERROR)
                end
            else
                vim.notify "qfstore: store cancelled"
            end
        end)
        return
    end

    local ok, res = qfstore.store { name = name, loclist = loclist }
    if ok then
        vim.notify(string.format("qfstore: stored %d items as '%s'", res, name))
    else
        vim.notify("qfstore: " .. res, vim.log.levels.ERROR)
    end
end

local function load_by_name_or_pick(name, loclist, picker_prompt)
    if name and name ~= "" then
        local ok, err = qfstore.load { name = name, loclist = loclist }
        if not ok then
            vim.notify("qfstore: " .. err, vim.log.levels.ERROR)
        else
            vim.notify("qfstore: loaded '" .. name .. "'")
        end
        return
    end

    qfstore.pick_entry(function(entry)
        if not entry then
            return
        end
        local ok, err = qfstore.load {
            name = entry.name,
            loclist = loclist,
        }
        if not ok then
            vim.notify("qfstore: " .. err, vim.log.levels.ERROR)
        else
            vim.notify("qfstore: loaded '" .. entry.name .. "'")
        end
    end, { prompt = picker_prompt })
end

local function remove_via_pick(picker_prompt)
    qfstore.pick_entry(function(entry)
        if not entry then
            return
        end
        local ok, err = qfstore.remove(entry.name)
        if ok then
            vim.notify("qfstore: removed '" .. entry.name .. "'")
        else
            vim.notify("qfstore: " .. err, vim.log.levels.ERROR)
        end
    end, { prompt = picker_prompt })
end

vim.api.nvim_create_user_command("QfStore", function(opts)
    store_with_collision_check(default_name(opts), false)
end, {
    nargs = "?",
    desc = "Store current quickfix list (.vim/lists/).",
})

vim.api.nvim_create_user_command("QfLoad", function(opts)
    local name = opts.fargs and opts.fargs[1]
    load_by_name_or_pick(name, false, "Load quickfix entry:")
end, {
    nargs = "?",
    desc = "Load a stored quickfix list.",
})

vim.api.nvim_create_user_command("QfRemove", function()
    remove_via_pick "Remove quickfix entry:"
end, {
    desc = "Remove a stored quickfix list via picker.",
})

vim.api.nvim_create_user_command("QfBrowseStore", function()
    qfstore.open_store()
end, {
    desc = "Browse the .vim/lists/ store directory in oil (read-only navigation).",
})

vim.api.nvim_create_user_command("LlStore", function(opts)
    store_with_collision_check(default_name(opts), true)
end, {
    nargs = "?",
    desc = "Store current location list (.vim/lists/).",
})

vim.api.nvim_create_user_command("LlLoad", function(opts)
    local name = opts.fargs and opts.fargs[1]
    load_by_name_or_pick(name, true, "Load location-list entry:")
end, {
    nargs = "?",
    desc = "Load a stored list into the current window's location list.",
})

vim.api.nvim_create_user_command("LlRemove", function()
    remove_via_pick "Remove location-list entry:"
end, {
    desc = "Remove a stored list via picker.",
})

vim.api.nvim_create_user_command("LlBrowseStore", function()
    qfstore.open_store()
end, {
    desc = "Browse the .vim/lists/ store directory in oil (read-only navigation).",
})
