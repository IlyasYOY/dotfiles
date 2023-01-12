local Link = require "functions.obsidian.link"

describe("from string", function()
    it("empty string", function()
        local result = Link.from_string ""
        assert(result == nil)
    end)

    it("raw link", function()
        local result = Link.from_string "name"
        assert(result ~= nil)
        assert(result.name == "name")
        assert(result.alias == nil)
        assert(result.header == nil)
    end)

    local headers = {
        "header",
        "big header",
    }
    for _, header in ipairs(headers) do
        it("with header '" .. header .. "'", function()
            local result = Link.from_string("name#" .. header)
            assert(result ~= nil)
            assert(result.name == "name")
            assert(result.alias == nil)
            assert(result.header == header)
        end)
    end

    local aliases = {
        "alias",
        "big alias",
    }
    for _, alias in ipairs(aliases) do
        it("with alias '" .. alias .. "'", function()
            local result = Link.from_string("name|" .. alias)
            assert(result ~= nil)
            assert(result.name == "name")
            assert(result.alias == alias)
            assert(result.header == nil)
        end)
    end
end)

describe("find link", function()
    local find_link = Link.find_link_at
    it("no link", function()
        local link = find_link("123 [[he 345", 6)
        assert(link == nil)
    end)

    it("miss link", function()
        local link = find_link("123 [[hello]] 345", 2)
        assert(link == nil)
    end)

    for _, num in ipairs { 7, 9, 11 } do
        it("has link with " .. num .. " index", function()
            local link = find_link("123 [[hello]] 345", num)
            assert(link ~= nil)
            assert(link.name == "hello")
        end)
    end
end)
