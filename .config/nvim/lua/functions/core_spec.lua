

describe("core tests", function()
    local core = require "functions/core"

    it("string split should work", function()
        local result = core.string_split("hello world", " ")

        assert(#result == 2, ("string splitted incorrectly, resulting %s"):format(#result))
    end)

    it("string split should work with default parameter", function()
        local result = core.string_split "hello world"

        assert(#result == 2, ("string splitted incorrectly, resulting %s"):format(#result))
    end)

end)
