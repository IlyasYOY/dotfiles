local Path = require "plenary.path"

local M = {}

local STORE_REL = Path:new ".vim" / "lists"
local SUFFIX = ".json"

--- @class QfStoreEntry
--- @field name string
--- @field path string
--- @field title string?
--- @field loclist boolean
--- @field mtime number
--- @field item_count number
--- @field saved_at string?
--- @field cwd string?

--- Absolute path to the quickfix store for the current working directory.
--- @return Path
local function store_dir()
    return Path:new(vim.fn.getcwd()) / STORE_REL
end

--- Ensure the store directory exists. Returns the absolute path string.
--- @return string dir, string? err
local function ensure_store_dir()
    local dir = store_dir()
    dir:mkdir { parents = true, exists_ok = true }
    return tostring(dir)
end

--- Resolve a quickfix item to a stable filename that survives across
--- sessions (transient bufnr values are not reusable after restart).
--- @param item table
--- @return string?
local function resolve_filename(item)
    if item.filename and item.filename ~= "" then
        return item.filename
    end
    if item.bufnr and item.bufnr ~= 0 then
        if vim.api.nvim_buf_is_valid(item.bufnr) then
            local name = vim.api.nvim_buf_get_name(item.bufnr)
            if name ~= "" then
                return name
            end
        end
    end
    return nil
end

--- Convert a live quickfix item into a JSON-storable shape. Items without
--- a resolvable filename are kept (with empty filename) so the list shape
--- is preserved, even though they will not be jumpable after reload.
--- @param item table
--- @return table
local function to_storable(item)
    return {
        filename = resolve_filename(item) or "",
        lnum = item.lnum or 0,
        col = item.col or 0,
        end_lnum = item.end_lnum or 0,
        end_col = item.end_col or 0,
        text = item.text or "",
        type = item.type or "",
        valid = item.valid or 0,
    }
end

--- Build the file path for a stored entry name.
--- @param name string
--- @return string
local function entry_path(name)
    return tostring(store_dir() / (name .. SUFFIX))
end

--- Check whether a stored entry exists.
--- @param name string
--- @return boolean
function M.exists(name)
    return vim.fn.filereadable(entry_path(name)) == 1
end

--- Read a stored entry from disk.
--- @param name string
--- @return table? data, string? err
local function read_entry(name)
    local path = entry_path(name)
    if vim.fn.filereadable(path) ~= 1 then
        return nil, "no stored entry named '" .. name .. "'"
    end
    local lines = vim.fn.readfile(path)
    if not lines then
        return nil, "failed to read '" .. path .. "'"
    end
    local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
    if not ok or type(decoded) ~= "table" then
        return nil, "failed to parse '" .. path .. "'"
    end
    return decoded
end

--- List all stored entries, newest first.
--- @return QfStoreEntry[]
function M.list()
    local dir = store_dir()
    if not dir:exists() then
        return {}
    end

    local entries = {}
    for _, child in ipairs(vim.fn.readdir(tostring(dir))) do
        if vim.endswith(child, SUFFIX) then
            local name = child:sub(1, #child - #SUFFIX)
            local path = tostring(dir / child)
            local data = read_entry(name)
            table.insert(entries, {
                name = name,
                path = path,
                title = data and data.title,
                loclist = data and data.loclist or false,
                mtime = vim.fn.getftime(path),
                item_count = data and data.items and #data.items or 0,
                saved_at = data and data.saved_at,
                cwd = data and data.cwd,
            })
        end
    end

    table.sort(entries, function(a, b)
        return a.mtime > b.mtime
    end)
    return entries
end

--- Store the current quickfix (or location list) under `name`.
--- @param opts { name?: string, loclist?: boolean, winid?: number }
--- @return boolean ok, number|string count_or_err
function M.store(opts)
    opts = opts or {}
    local loclist = opts.loclist == true
    local winid = opts.winid or 0
    local name = opts.name
    if not name or name == "" then
        name = os.date "%Y%m%d-%H%M%S"
    end

    local items
    local title
    if loclist then
        items = vim.fn.getloclist(winid)
        title = vim.fn.getloclist(winid, { title = 1 }).title
    else
        items = vim.fn.getqflist()
        title = vim.fn.getqflist({ title = 1 }).title
    end

    if not items or #items == 0 then
        return false, "list is empty"
    end

    local storable = {}
    for _, item in ipairs(items) do
        table.insert(storable, to_storable(item))
    end

    local payload = {
        title = title,
        loclist = loclist,
        saved_at = os.date "%Y-%m-%d %H:%M:%S",
        cwd = vim.fn.getcwd(),
        items = storable,
    }

    ensure_store_dir()
    local path = entry_path(name)
    local encoded = vim.json.encode(payload)
    vim.fn.writefile({ encoded }, path)

    return true, #storable
end

--- Load a stored entry and push it as a new quickfix (or location) list,
--- appending to the quickfix stack rather than replacing the current list.
--- @param opts { name: string, loclist?: boolean, winid?: number }
--- @return boolean ok, string? err
function M.load(opts)
    opts = opts or {}
    local name = opts.name
    if not name or name == "" then
        return false, "name is required"
    end

    local data, err = read_entry(name)
    if not data then
        return false, err
    end

    local loclist = opts.loclist
    if loclist == nil then
        loclist = data.loclist == true
    end
    local winid = opts.winid or 0

    local what = {
        title = data.title,
        items = data.items or {},
    }

    if loclist then
        vim.fn.setloclist(winid, {}, " ", what)
    else
        vim.fn.setqflist({}, " ", what)
    end

    if not loclist then
        vim.cmd "botright copen"
    end

    return true
end

--- Remove a stored entry from disk.
--- @param name string
--- @return boolean ok, string? err
function M.remove(name)
    if not M.exists(name) then
        return false, "no stored entry named '" .. name .. "'"
    end
    local ok, rm_err = pcall(vim.fn.delete, entry_path(name))
    if not ok then
        return false, rm_err
    end
    return true
end

--- Open the store directory in oil.nvim (falls back to `:edit`).
function M.open_store()
    local dir = ensure_store_dir()
    local ok, oil = pcall(require, "oil")
    if ok and oil then
        oil.open(dir)
        return
    end
    vim.cmd("edit " .. vim.fn.fnameescape(dir))
end

--- Present a `vim.ui.select` picker over stored entries.
--- @param on_choice fun(entry: QfStoreEntry?)
--- @param opts? { prompt?: string }
function M.pick_entry(on_choice, opts)
    opts = opts or {}
    local entries = M.list()
    if #entries == 0 then
        vim.notify("qfstore: no stored entries", vim.log.levels.WARN)
        on_choice(nil)
        return
    end
    vim.ui.select(entries, {
        prompt = opts.prompt or "Select quickfix entry:",
        format_item = function(e)
            local tag = e.loclist and "[loc]" or "[qf] "
            return string.format(
                "%s %-24s %3d items  %s  (%s)",
                tag,
                e.name,
                e.item_count,
                e.title or "",
                e.saved_at or ""
            )
        end,
    }, function(choice)
        on_choice(choice)
    end)
end

return M
