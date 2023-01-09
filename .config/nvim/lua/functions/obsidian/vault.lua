local core = require "functions.core"
local Templater = require "functions.obsidian.templater"
local Path = require "plenary.path"
local File = require "functions.obsidian.file"
local Journal = require "functions.obsidian.journal"
local obsidian_telescope = require "functions.obsidian.telescope"

-- table with vault options
--- @class VaultOpts
--- @field public vault_home string?
--- @field public templater TemplaterOpts?
--- @field public journal JournalOpts?
local VaultOpts = {}

-- simple constructor for options
--- @param opts VaultOpts?
function VaultOpts:new(opts)
    opts = opts or {}
    self.__index = self
    local vault_opts = setmetatable({}, self)

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

-- class representing vaults
--- @class Vault
--- @field protected _templates_path Path
--- @field protected _home_path Path
--- @field protected _templater Templater
--- @field protected _journal Journal
local Vault = {}

function Vault:find_and_insert_template(opts)
    self._templater:search_and_insert_template(opts)
end

function Vault:find_note()
    obsidian_telescope.find_files("Find notes", self._home_path:expand())
end

function Vault:grep_note()
    obsidian_telescope.grep_files("Grep notes", self._home_path:expand())
end

function Vault:follow_link()
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local name_with_alias = core.find_link(line, col + 1)
    if name_with_alias ~= nil then
        local name = string.gsub(name_with_alias, "[|#].*", "")
        local note = self:get_note(name)
        if note ~= nil then
            vim.fn.execute("edit " .. note.path)
            return
        end
    end
    vim.notify "No link was found under the cursor"
end

function Vault:is_current_buffer_in_vault()
    local file_name = vim.api.nvim_buf_get_name(0)
    return core.string_has_prefix(file_name, self._home_path:expand(), true)
end

---@param name string
function Vault:open_note(name)
    local note = self:get_note(name)
    vim.fn.execute("edit " .. note.path)
end

---@param name string
---@return ilyasyoy.File
function Vault:get_note(name)
    local notes = self:list_notes()

    for _, note in ipairs(notes) do
        if note.name == name then
            return note
        end
    end
end

function Vault:open_daily()
    self._journal:open_daily()
end

function Vault:find_journal()
    self._journal:find_daily()
end

function Vault:list_notes()
    local result = File.list(self._home_path:expand(), "**/*.md")
    return result
end

-- creates Vault instance
--- @param opts VaultOpts? table options to create a vault
--- @return Vault
function Vault:new(opts)
    opts = opts or {}

    self.__index = self
    local vault = setmetatable({}, self)

    opts = VaultOpts:new(opts)

    --- @type Path
    vault._home_path = Path:new(opts.vault_home)
    --- @type Templater
    local templater = Templater:new(opts.templater)

    vault._templater = templater
    vault._journal = Journal:new(templater, opts.journal)

    return vault
end

return Vault
