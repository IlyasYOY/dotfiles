describe("core tests", function()
    local core = require "ilyasyoy.functions.core"

    describe("has suffix", function()
        it("nil suffix", function()
            assert(core.string_has_suffix("test", nil) == false)
        end)

        it("nil string", function()
            assert(core.string_has_suffix(nil, "test") == false)
        end)

        it("no suffix", function()
            assert(core.string_has_suffix("test.txt", ".md") == false)
        end)

        it("has suffix", function()
            assert(core.string_has_suffix("test.txt", ".txt"))
        end)
    end)

    describe("string split", function()
        local string_split = core.string_split
        it("string split should work", function()
            local result = string_split("hello world", " ")

            assert(
                #result == 2,
                ("string splitted incorrectly, resulting %s"):format(#result)
            )
        end)

        it("string split should work with default parameter", function()
            local result = string_split "hello world"

            assert(
                #result == 2,
                ("string splitted incorrectly, resulting %s"):format(#result)
            )
        end)
    end)

    describe("starts_with", function()
        local starts_with = core.string_has_prefix

        it("str param is nil", function()
            local result = starts_with(nil, "test")
            assert(not result)
        end)

        it("prefix param is nil", function()
            local result = starts_with("abc test", nil)
            assert(not result)
        end)

        it("found prefix", function()
            local result = starts_with("abc test", "abc")
            assert(result)
        end)

        it("found not prefix", function()
            local result = starts_with("test abc ", "abc")
            assert(not result)
        end)

        it("not found", function()
            local result = starts_with("test abc ", "abc")
            assert(not result)
        end)
    end)

    describe("strip prefix", function()
        local strip_prefix = core.string_strip_prefix
        it("no prefix", function()
            local result = strip_prefix("aaa abc", "abc")
            assert(result == "aaa abc")
        end)
        it("not in prefix", function()
            local result = strip_prefix("aaa bbb", "abc")
            assert(result == "aaa bbb")
        end)
        it("remove prefix ", function()
            local result = strip_prefix("abc aaa", "abc")
            assert(result == " aaa")
        end)
    end)

    describe("get nested field", function()
        local get_nested = core.get_nested_field

        it("from nil", function()
            local result = get_nested(nil, "some", "thing")
            assert(result == nil)
        end)

        it("from first layer", function()
            local result = get_nested({ some = "cool" }, "some", "thing")
            assert(result == nil)
        end)

        it("from second layer", function()
            local result =
                get_nested({ some = { thing = "cool" } }, "some", "thing")
            assert(result == "cool")
        end)

        it("from second layer no match", function()
            local result =
                get_nested({ some = { thing = "cool" } }, "some", "lol")
            assert(result == nil)
        end)
    end)

    describe("array operation", function()
        local map = core.array_map

        describe("map", function()
            local cases = {
                empty = {
                    input = {},
                    expected = {},
                },
                singleton = {
                    input = { 1 },
                    expected = { 2 },
                },
                big = {
                    input = { 1, 7, 16 },
                    expected = { 2, 14, 32 },
                },
            }

            for name, case in pairs(cases) do
                it(name .. " list", function()
                    local result = map(case.input, function(x)
                        return x * 2
                    end)
                    assert(vim.deep_equal(result, case.expected))
                end)
            end
        end)

        describe("filter", function()
            local filter = core.array_filter

            local cases = {
                empty = {
                    input = {},
                    expected = {},
                },
                ["singleton not passes"] = {
                    input = { 1 },
                    expected = {},
                },
                ["singleton passes"] = {
                    input = { 2 },
                    expected = { 2 },
                },
                ["some pass some not"] = {
                    input = { 1, 7, 8, 4, 9, 10 },
                    expected = { 8, 4, 10 },
                },
            }

            for name, case in pairs(cases) do
                it(name .. " list", function()
                    local result = filter(case.input, function(x)
                        return x % 2 == 0
                    end)
                    assert(vim.deep_equal(result, case.expected))
                end)
            end
        end)

        describe("flat_map", function()
            local flat_map = core.array_flat_map

            local cases = {
                empty = {
                    input = {},
                    expected = {},
                },
                ["single item"] = {
                    input = { 2 },
                    expected = { 2, 4 },
                },
                ["multiple items"] = {
                    input = { 2, 7, 3 },
                    expected = { 2, 4, 7, 14, 3, 6 },
                },
            }

            for name, case in pairs(cases) do
                it(name .. " list", function()
                    local result = flat_map(case.input, function(x)
                        return { x, x * 2 }
                    end)
                    assert(
                        vim.deep_equal(result, case.expected),
                        string.format(
                            "Expected %s, but was %s",
                            vim.inspect(case.expected),
                            vim.inspect(result)
                        )
                    )
                end)
            end
        end)
    end)
end)
