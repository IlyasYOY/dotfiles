local Path = require "plenary.path"
local File = require "functions.obsidian.file"
local telescope = require "functions.obsidian.telescope"

-- journal opts
---@class JournalOpts
---@field public home string
---@field public template_name string
---@field public date_provider? fun():string
local JournalOpts = {}

-- constructor for options
--- @param opts JournalOpts?
function JournalOpts:new(opts)
    opts = opts or {}

    self.__index = self
    local journalOpts = setmetatable({}, self)

    return vim.tbl_deep_extend("force", journalOpts, opts)
end

-- daily notes class
--- @class Journal
--- @field private _templater Templater templater generator
--- @field private _date_provider fun(): string the result is used as a file name to the entry
--- @field protected _home_path Path home location for daily notes
--- @field protected _template_name string template name to be used in daily notes
local Journal = {}

-- create new Journal
--- @param templater Templater
--- @param opts JournalOpts?
function Journal:new(templater, opts)
    opts = JournalOpts:new(opts)

    self.__index = self
    local journal = setmetatable({}, self)

    journal._templater = templater
    journal._home_path = Path:new(opts.home)
    journal._template_name = opts.template_name
    journal._date_provider = opts.date_provider
        or function()
            return os.date "%Y-%m-%d"
        end

    return journal
end

function Journal:open_daily()
    local daily_note = self:today(true)
    vim.fn.execute("edit " .. daily_note.path)
end

function Journal:find_daily()
    return telescope.find_files("Dailies", self._home_path:expand())
end

-- lists journal entries
--- @return Array<ilyasyoy.File>
function Journal:list_dailies()
    local path = self._home_path:expand()
    local files = File.list(path, "????-??-??.md")
    return files
end

-- get today note file
--- @param create_if_missing boolean?
--- @return ilyasyoy.File
function Journal:today(create_if_missing)
    local filename = self._date_provider()
    --- @type Path
    local path = self._home_path / (filename .. ".md")

    if create_if_missing and not path:exists() then
        path:touch()
        if self._template_name then
            local templated_text = self._templater:process {
                filename = filename,
                template_name = self._template_name,
            }
            path:write(templated_text, "w")
        end
    end

    return File:new(path:expand())
end

return Journal
