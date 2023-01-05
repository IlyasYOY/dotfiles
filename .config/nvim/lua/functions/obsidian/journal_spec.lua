local Path = require "plenary.path"
local Journal = require "functions.obsidian.journal"
local Templater = require "functions.obsidian.templater"

local spec_utils = require "functions.spec_utils"
local core = require "functions.core"

local function journal_fixture()
    local result = {}

    local journal_dir_path = spec_utils.temp_dir_fixture()
    local templates_dir_path = spec_utils.temp_dir_fixture()

    result.journal_dir_path = journal_dir_path
    result.templates_dir_path = templates_dir_path

    before_each(function()
        local templater =
            Templater:new { home = templates_dir_path.path:expand() }
        result.templater = templater

        result.journal_with_date_provider = function(opts)
            opts = opts or {}

            result.journal = Journal:new(templater, {
                home = journal_dir_path.path:expand(),
                date_provider = opts.date_provider,
                template_name = opts.template_name,
            })
        end

        result.journal_with_date_provider()
    end)

    return result
end

describe("journal", function()
    local test_state = journal_fixture()

    describe("today", function()
        it("get", function()
            test_state.journal_with_date_provider {
                date_provider = function()
                    return "2022-12-12"
                end,
            }

            local result = test_state.journal:today()

            assert(result.name == "2022-12-12")
            assert(core.string_has_suffix(result.path, ".md"))
        end)

        it("get and not create", function()
            test_state.journal_with_date_provider {
                date_provider = function()
                    return "2022-12-12"
                end,
            }

            local result = test_state.journal:today()

            --- @type Path
            local path = Path:new(result.path)

            assert(path:exists() == false)
        end)

        it("get and create", function()
            test_state.journal_with_date_provider {
                date_provider = function()
                    return "2022-12-12"
                end,
            }

            local result = test_state.journal:today(true)

            --- @type Path
            local path = Path:new(result.path)

            assert(path:exists())
        end)

        it("create matching template", function()
            test_state.journal_with_date_provider {
                date_provider = function()
                    return "2022-12-12"
                end,
                template_name = "daily",
            }

            --- @type Path
            local daily_file_template = Path:new(
                test_state.templates_dir_path.path
            ) / "daily.md"

            local expected_text = "this is example template 2022-12-12"
            daily_file_template:write(expected_text, "w")

            local result = test_state.journal:today(true)

            --- @type Path
            local path = Path:new(result.path)
            local resulting_text = path:read()
            assert(
                resulting_text == expected_text,
                string.format(
                    "Expected mathing template '%s' but was '%s'",
                    expected_text,
                    resulting_text
                )
            )
        end)
    end)

    describe("list", function()
        local state = journal_fixture()

        it("no entries", function()
            local result = state.journal:list_dailies()

            assert(#result == 0)
        end)

        it("correct entries", function()
            local first_note = state.journal_dir_path.path / "2022-12-11.md"
            first_note:touch {}
            local second_note = state.journal_dir_path.path / "2022-12-12.md"
            second_note:touch {}

            local result = state.journal:list_dailies()

            assert(#result == 2, string.format("Found %s", vim.inspect(result)))
        end)
    end)
end)
