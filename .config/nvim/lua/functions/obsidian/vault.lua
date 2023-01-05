local Templater = require "functions.obsidian.templater"
local Path = require "plenary.path"
local Journal = require "functions.obsidian.journal"

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
    local vaultOpts = setmetatable({}, self)

    vaultOpts.vault_home = opts.vault_home
        or (Path:new(Path.path.home) / "vimwiki"):expand()

    vaultOpts.templates_home = (
        Path:new(vaultOpts.vault_home)
        / "meta"
        / "templates"
    ):expand()

    vaultOpts.journal_home = (Path:new(vaultOpts.vault_home) / "diary"):expand()

    local templater_opts = opts.templater or {}
    vaultOpts.templater = vim.tbl_extend(
        "force",
        { home = vaultOpts.templates_home, include_default_providers = true },
        templater_opts
    )

    local journal_opts = opts.journal or {}
    vaultOpts.journal = vim.tbl_extend("force", {
        home = vaultOpts.journal_home,
    }, journal_opts)

    return vaultOpts
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

function Vault:open_daily()
    self._journal:open_daily()
end

function Vault:find_journal()
    self._journal:find_daily()
end

-- creates Vault instance
--- @param opts VaultOpts? table options to craete a vault
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
