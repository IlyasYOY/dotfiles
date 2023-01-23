local Vault = require "ilyasyoy.functions.obsidian.vault"
local spec = require "coredor.spec"

local function vault_fixture()
    local result = {}

    local vault_home = spec.temp_dir_fixture()

    before_each(function()
        result.vault = Vault:new {
            vault_home = vault_home.path:expand(),
        }
        result.home = vault_home.path
    end)

    return result
end

describe("find backlinks", function()
    local state = vault_fixture()

    it("no note", function()
        local note = (state.home / "note.md")
        note:touch()

        local backlinks = state.vault:list_backlinks "note1"

        assert.list_size(backlinks, 0)
    end)

    it("no backlinks", function()
        local note = (state.home / "note.md")
        note:touch()

        local backlinks = state.vault:list_backlinks "note"

        assert.list_size(backlinks, 0)
    end)

    it("one backlink", function()
        ---@type Path
        local note1 = (state.home / "note1.md")
        note1:touch()
        note1:write("This is file with a link to [[note]].", "w")

        local note = (state.home / "note.md")
        note:touch()

        local backlinks = state.vault:list_backlinks "note"

        assert.list_size(backlinks, 1)
        assert.file(backlinks[1], "note1", note1:expand())
    end)

    it("multiple backlink", function()
        ---@type Path
        local note1 = (state.home / "note1.md")
        note1:touch()
        note1:write("This is file with a link to [[note]].", "w")

        ---@type Path
        local note2 = (state.home / "note2.md")
        note2:touch()
        note2:write("This is the second file with a link to [[note]].", "w")

        local note = (state.home / "note.md")
        note:touch()

        local backlinks = state.vault:list_backlinks "note"

        assert.list_size(backlinks, 2)
    end)

    it("multiple links per file backlink", function()
        ---@type Path
        local note1 = (state.home / "note1.md")
        note1:touch()
        note1:write(
            "This is file with a link to [[note]] and one more [[note]].",
            "w"
        )

        local note = (state.home / "note.md")
        note:touch()

        local backlinks = state.vault:list_backlinks "note"

        assert.list_size(backlinks, 1)
    end)
end)

describe("list", function()
    local state = vault_fixture()

    it("no items", function()
        local notes = state.vault:list_notes()

        assert.list_size(notes, 0)
    end)

    it("list item", function()
        local file = (state.home / "note1.md")
        file:touch()

        local notes = state.vault:list_notes()

        local note = notes[#notes]

        assert.file(note, "note1", file:expand())
    end)

    it("md items", function()
        local file0 = (state.home / "note1.md")
        local file1 = (state.home / "note2.md")
        file0:touch()
        file1:touch()

        local notes = state.vault:list_notes()

        assert.list_size(notes, 2)
    end)

    it("nested md items", function()
        local nested_dir = state.home / "dir"
        nested_dir:mkdir()

        local file0 = (nested_dir / "note1.md")
        local file1 = (nested_dir / "note2.md")

        file0:touch()
        file1:touch()

        local notes = state.vault:list_notes()

        assert.list_size(notes, 2)
    end)

    it("not md items", function()
        local file0 = (state.home / "note1.txt")
        local file1 = (state.home / "note2.txt")
        file0:touch()
        file1:touch()

        local notes = state.vault:list_notes()

        assert.list_size(notes, 0)
    end)
end)
