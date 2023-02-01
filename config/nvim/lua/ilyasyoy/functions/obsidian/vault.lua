local Link = require "ilyasyoy.functions.obsidian.link"
local Templater = require "ilyasyoy.functions.obsidian.templater"
local File = require "coredor.file"
local Journal = require "ilyasyoy.functions.obsidian.journal"
local Path = require "plenary.path"

local obsidian_telescope = require "ilyasyoy.functions.obsidian.telescope"
local core = require "coredor"

-- table with vault options
---@class ilyasyoy.obsidian.VaultOpts
---@field public vault_home string?
---@field public templater ilyasyoy.obsidian.TemplaterOpts?
---@field public journal ilyasyoy.obsidian.JournalOpts?
---@field public time_provider fun():number
local VaultOpts = {}

-- simple constructor for options
---@param opts ilyasyoy.obsidian.VaultOpts?
function VaultOpts:new(opts)
    opts = opts or {}
    self.__index = self
    local vault_opts = setmetatable({}, self)

    vault_opts.time_provider = opts.time_provider or os.clock

    vault_opts.vault_home = opts.vault_home
        or (Path:new(Path.path.home) / "vimwiki"):expand()

    vault_opts.templates_home = (
        Path:new(vault_opts.vault_home)
        / "meta"
        / "templates"
    ):expand()

    vault_opts.journal_home = (Path:new(vault_opts.vault_home) / "diary"):expand()

    local templater_opts = opts.templater or {}
    vault_opts.templater = vim.tbl_extend(
        "force",
        { home = vault_opts.templates_home, include_default_providers = true },
        templater_opts
    )

    local journal_opts = opts.journal or {}
    vault_opts.journal = vim.tbl_extend("force", {
        home = vault_opts.journal_home,
    }, journal_opts)

    return vault_opts
end

---@class ilyasyoy.obsidian.Vault
---@field protected _templates_path Path
---@field protected _home_path Path
---@field protected _templater ilyasyoy.obsidian.Templater
---@field protected _journal ilyasyoy.obsidian.Journal
---@field protected _time_provider fun(): number
local Vault = {}

---creates Vault instance
---@param opts ilyasyoy.obsidian.VaultOpts? table options to create a vault
---@return ilyasyoy.obsidian.Vault
function Vault:new(opts)
    opts = opts or {}

    self.__index = self
    local vault = setmetatable({}, self)

    opts = VaultOpts:new(opts)

    ---@type Path
    vault._home_path = Path:new(opts.vault_home)
    ---@type ilyasyoy.obsidian.Templater
    local templater = Templater:new(opts.templater)

    vault._templater = templater
    vault._journal = Journal:new(templater, opts.journal)
    vault._time_provider = opts.time_provider

    return vault
end

---create notes with defaults to name structure applied
---@param name string?
---@return coredor.File?
function Vault:create_note(name)
    local time = self._time_provider()
    if not name or name == "" then
        name = time
    end

    local name_prefix = os.date "%Y-%m-%d "
    local fullname = name_prefix .. name
    if self:get_note(fullname) then
        return nil
    end

    ---@type Path
    local new_path = self._home_path / (fullname .. ".md")
    new_path:touch()
    return File:new(new_path:expand())
end

function Vault:find_and_insert_template()
    self._templater:search_and_insert_template()
end

function Vault:find_note()
    obsidian_telescope.find_files("Find notes", self._home_path:expand())
end

function Vault:find_current_note_backlinks()
    local current_note = File:new(core.current_working_file())
    self:find_backlinks(current_note.name)
end

function Vault:find_journal()
    self._journal:find_journal()
end

---renames the note
---@param name string
---@param new_name string
---@return coredor.File?
function Vault:rename(name, new_name)
    local note = self:get_note(name)
    if note == nil then
        vim.notify("note '" .. name .. "' was not found")
        return
    end
    -- NOTE: Maybe I should do something like string_ensure_prefix/string_ensure_suffix.
    local new_name_with_extension = (new_name .. ".md")
    local new_path = self._home_path / new_name_with_extension
    -- TODO: Move into coredor.File
    local status = note._plenary_path:rename {
        new_name = new_path:expand(),
    }
    return self:get_note(new_name)
end

function Vault:find_backlinks(name)
    local notes = self:list_backlinks(name)

    obsidian_telescope.find_through_items(
        "Backlinks",
        notes,
        nil,
        function(entry)
            return {
                value = entry.path,
                display = entry.name,
                ordinal = entry.name,
            }
        end
    )
end

function Vault:grep_note()
    obsidian_telescope.grep_files("Grep notes", self._home_path:expand())
end

---follows a link under the cursor
function Vault:follow_link()
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local link = Link.find_link_at(line, col + 1)
    if link ~= nil then
        local name = link.name
        local note = self:get_note(name)
        if note ~= nil then
            vim.fn.execute("edit " .. note.path)
            return
        end
    end
    vim.notify "No link was found under the cursor"
end

---checks if this buffer in the vault, usefull in autocommands.
---@return boolean
function Vault:is_current_buffer_in_vault()
    local file_name = vim.api.nvim_buf_get_name(0)
    return core.string_has_prefix(file_name, self._home_path:absolute(), true)
end

---checks if this buffer in the vault, usefull in autocommands.
---@return boolean
function Vault:is_current_buffer_a_note()
    return self:is_current_buffer_in_vault() and vim.bo.filetype == "markdown"
end

---checks if this buffer in the vault, usefull in autocommands.
---@param callback fun()
function Vault:run_if_note(callback)
    if self:is_current_buffer_a_note() then
        callback()
    else
        vim.notify "Current buffer is not a note"
    end
end

---opens note to edit
---@param name string
function Vault:open_note(name)
    local note = self:get_note(name)
    if note ~= nil then
        vim.fn.execute("edit " .. note.path)
    else
        vim.notify("No note for name " .. name)
    end
end

---get note from vault using name of the file
---@param name string
---@return coredor.File?
function Vault:get_note(name)
    local notes = self:list_notes()

    for _, note in ipairs(notes) do
        if note.name == name then
            return note
        end
    end
end

--- Opens daily note to be edited
function Vault:open_daily()
    self._journal:open_daily()
end

---lists notes from vault
---@return coredor.File[]
function Vault:list_notes()
    return File.list(self._home_path:expand(), "**/*.md")
end

---lists backlinks to a note using name
---@param name string
---@return coredor.File[]
function Vault:list_backlinks(name)
    local note_for_name = self:get_note(name)
    if note_for_name == nil then
        return {}
    end

    ---@type coredor.File[]
    local notes_with_backlinks = {}
    local notes = self:list_notes()
    for _, note in ipairs(notes) do
        local text = note:read()
        local links = Link.from_text(text)
        local has_backlink = false
        for _, link in ipairs(links) do
            if link.name == name then
                has_backlink = true
            end
        end
        if has_backlink then
            table.insert(notes_with_backlinks, note)
        end
    end

    return notes_with_backlinks
end

return Vault
