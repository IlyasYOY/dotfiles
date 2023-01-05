describe("git stuff", function()
  local git = require "functions/git"
  it("url to link", function()
    local url_to_link = git.url_to_link
    it("nil param", function()
      local result = url_to_link(nil)
      assert(not result)
    end)
    it("https link", function()
      local result = url_to_link "https://github.com/rafcamlet/nvim-luapad.git"
      assert(result == "https://github.com/rafcamlet/nvim-luapad")
    end)
    it("ssh link", function()
      local result = url_to_link "git@github.com:rafcamlet/nvim-luapad.git"
      assert(result == "https://github.com/rafcamlet/nvim-luapad")
    end)
  end)

  it("resolve link to a file", function()
    local master_branch = "master"
    local test_link = "https://github.com/IlyasYOY/python-streamer"
    local test_filepath = ".gitignore"

    it("test with master", function()
      local link =
        git.resolve_link_to_current_working_file(test_link, master_branch, test_filepath)
      assert(
        link == "https://github.com/IlyasYOY/python-streamer/blob/master/.gitignore"
      )
    end)
    it("test with not master", function()
      local link =
        git.resolve_link_to_current_working_file(test_link, "test", test_filepath)
      assert(link == "https://github.com/IlyasYOY/python-streamer/blob/test/.gitignore")
    end)
  end)

  it("resolve link to a line", function()
    local master_branch = "master"
    local test_link = "https://github.com/IlyasYOY/python-streamer"
    local test_filepath = ".gitignore"

    it("test with master", function()
      local link =
        git.resolve_link_to_current_line(test_link, master_branch, test_filepath, 14)
      assert(
        link == "https://github.com/IlyasYOY/python-streamer/blob/master/.gitignore#L14"
      )
    end)
    it("test with not master", function()
      local link = git.resolve_link_to_current_line(test_link, "test", test_filepath, 19)
      assert(
        link == "https://github.com/IlyasYOY/python-streamer/blob/test/.gitignore#L19"
      )
    end)
  end)
end)
