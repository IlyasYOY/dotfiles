local git = require "ilyasyoy.functions.git"

describe("repo url to link", function()
    local url_to_link = git.url_to_link

    it("nil param", function()
        local result = url_to_link(nil)
        assert.is_nil(result, "wrong nil param processing")
    end)

    it("https link", function()
        local result =
            url_to_link "https://github.com/rafcamlet/nvim-luapad.git"
        assert.are.equal(
            "https://github.com/rafcamlet/nvim-luapad",
            result,
            "wrong https link procssing"
        )
    end)

    it("ssh link", function()
        local result = url_to_link "git@github.com:rafcamlet/nvim-luapad.git"
        assert.are.equal(
            "https://github.com/rafcamlet/nvim-luapad",
            result,
            "wrong ssh link processing"
        )
    end)
end)

describe("link to a file", function()
    local master_branch = "master"
    local test_link = "https://github.com/IlyasYOY/python-streamer"
    local test_filepath = ".gitignore"

    it("test with master", function()
        local link = git.resolve_link_to_current_working_file(
            test_link,
            master_branch,
            test_filepath
        )
        assert.are.equal(
            "https://github.com/IlyasYOY/python-streamer/blob/master/.gitignore",
            link
        )
    end)

    it("test with not master", function()
        local link = git.resolve_link_to_current_working_file(
            test_link,
            "test",
            test_filepath
        )
        assert.are.equal(
            "https://github.com/IlyasYOY/python-streamer/blob/test/.gitignore",
            link
        )
    end)
end)

describe("link to a line", function()
    local master_branch = "master"
    local test_link = "https://github.com/IlyasYOY/python-streamer"
    local test_filepath = ".gitignore"

    it("test with master", function()
        local link = git.resolve_link_to_current_line(
            test_link,
            master_branch,
            test_filepath,
            14
        )
        assert.are.equal(
            "https://github.com/IlyasYOY/python-streamer/blob/master/.gitignore#L14",
            link
        )
    end)
    it("test with not master", function()
        local link = git.resolve_link_to_current_line(
            test_link,
            "test",
            test_filepath,
            19
        )
        assert.are.equal(
            "https://github.com/IlyasYOY/python-streamer/blob/test/.gitignore#L19",
            link
        )
    end)
end)
