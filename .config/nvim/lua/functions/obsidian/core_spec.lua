local core = require "functions.obsidian.core"

describe("find link", function()
    local find_link = core.find_link
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
            assert(link == "hello")
        end)
    end
end)
