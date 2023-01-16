local Templater = require "ilyasyoy.functions.obsidian.templater"
local spec_utils = require "ilyasyoy.functions.spec_utils"

describe("templater test", function()
    local templater
    local temp_dir_data = spec_utils.temp_dir_fixture()

    describe("proccess files", function()
        it("no files", function()
            templater = Templater:new {
                home = temp_dir_data.path:expand(),
            }

            local templates = templater:list_templates()

            assert(#templates == 0)
        end)

        it("not md", function()
            local kitty_file = temp_dir_data.path / "kitty.a"
            local hello_file = temp_dir_data.path / "hello.txt"
            kitty_file:touch {}
            hello_file:touch {}

            templater = Templater:new {
                home = temp_dir_data.path:expand(),
            }

            local templates = templater:list_templates()

            assert(#templates == 0)
        end)

        it("md", function()
            local kitty_file = temp_dir_data.path / "kitty.md"
            local hello_file = temp_dir_data.path / "hello.md"
            kitty_file:touch {}
            hello_file:touch {}

            templater = Templater:new {
                home = temp_dir_data.path:expand(),
            }

            local templates = templater:list_templates()

            assert(#templates == 2)
        end)

        it("entry structure", function()
            local kitty_file = temp_dir_data.path / "kitty.md"
            kitty_file:touch {}

            templater = Templater:new {
                home = temp_dir_data.path:expand(),
            }

            local templates = templater:list_templates()

            assert(#templates == 1)
            local template = templates[1]
            assert(template.name == "kitty")
            assert(template.path == kitty_file:expand())
        end)
    end)

    describe("process string", function()
        local template
        local result

        it("empty string", function()
            template = ""
            templater = Templater:new {}
            result = templater:_process_for_current_buffer(template)
            assert(result == "")
        end)

        it("default variables", function()
            template = "Simple template with {{date}}"
            templater = Templater:new()
            result = templater:_process_for_current_buffer(template)
            assert(result ~= template)
        end)

        it("var", function()
            template = "Simple template with {{date}}"
            templater = Templater:new {}
            templater:add_var_provider("date", function()
                return "2022-12-31"
            end)
            result = templater:_process_for_current_buffer(template)
            assert(result == "Simple template with 2022-12-31")
        end)

        it("multiple vars", function()
            template = "Simple template with {{date}} {{title}}"
            templater = Templater:new {}
            templater:add_var_provider("date", function()
                return "2022-12-31"
            end)
            templater:add_var_provider("title", function()
                return "Cool Title"
            end)
            result = templater:_process_for_current_buffer(template)
            assert(result == "Simple template with 2022-12-31 Cool Title")
        end)

        it("override var", function()
            template = "Simple template with {{date}}"
            templater = Templater:new {}
            templater:add_var_provider("date", function()
                return "2022-12-31"
            end)
            templater:add_var_provider("date", function()
                return "2022-12-30"
            end)
            result = templater:_process_for_current_buffer(template)
            assert(result == "Simple template with 2022-12-30")
        end)
    end)
end)
