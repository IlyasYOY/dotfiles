local Vault = require "ilyasyoy.functions.obsidian.vault"
local spec_utils = require "ilyasyoy.functions.spec_utils"

local function vault_fixture()
    local result = {}

    local vault_home = spec_utils.temp_dir_fixture()

    before_each(function()
        result.vault = Vault:new {
            vault_home = vault_home.path:expand(),
        }
        result.home = vault_home.path
    end)

    return result
end

describe("vault", function()
    local state = vault_fixture()
    describe("list", function()
        it("no items", function()
            local notes = state.vault:list_notes()

            assert(#notes == 0)
        end)

        it("list item", function()
            local file = (state.home / "note1.md")
            file:touch()

            local notes = state.vault:list_notes()

            local note = notes[#notes]

            assert(note.path == file:expand())
            assert(note.name == "note1")
        end)

        it("md items", function()
            local file0 = (state.home / "note1.md")
            local file1 = (state.home / "note2.md")
            file0:touch()
            file1:touch()

            local notes = state.vault:list_notes()

            assert(#notes == 2)
        end)

        it("nested md items", function()
            local nested_dir = state.home / "dir"
            nested_dir:mkdir()

            local file0 = (nested_dir / "note1.md")
            local file1 = (nested_dir / "note2.md")

            file0:touch()
            file1:touch()

            local notes = state.vault:list_notes()

            assert(#notes == 2)
        end)

        it("not md items", function()
            local file0 = (state.home / "note1.txt")
            local file1 = (state.home / "note2.txt")
            file0:touch()
            file1:touch()

            local notes = state.vault:list_notes()

            assert(#notes == 0)
        end)
    end)
end)
