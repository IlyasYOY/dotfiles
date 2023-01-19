local core = require "ilyasyoy.functions.core"

describe("has suffix", function()
    it("nil parameter", function()
        assert.is_false(
            core.string_has_suffix("test", nil),
            "must returns nil when parameter is nil"
        )
    end)

    for _, str in ipairs {
        "test.txt",
        "test.md.txt",
        "testmd",
    } do
        it("'" .. str .. "' is false for '.md' suffix", function()
            assert.is_false(
                core.string_has_suffix(str, ".md", true),
                "prefix was found even though it was absent"
            )
        end)
    end

    it("is true", function()
        assert.is_true(
            core.string_has_suffix("test.txt", ".txt", true),
            "prefix was not found"
        )
    end)
end)

describe("string split", function()
    local string_split = core.string_split

    local function check_hello_world_split(split)
        assert.are.equal(2, #split, "string should be spit in two words")
        assert.are.equal("hello", split[1], "first word is wrong")
        assert.are.equal("world", split[2], "second word is wrong")
    end

    it("no splits found", function()
        local result = string_split("hello world", "x")
        assert.are.equal(1, #result, "string should not be split, but it was")
        assert.are.equal(
            "hello world",
            result[#result],
            "string itself is the only element of the array"
        )
    end)

    it("works with space", function()
        local result = string_split("hello world", " ")
        check_hello_world_split(result)
    end)

    it("works with .", function()
        local result = string_split("hello.world", ".")
        check_hello_world_split(result)
    end)

    it("work with new line separator", function()
        local result = string_split("hello\nworld", "\n")
        check_hello_world_split(result)
    end)
end)

describe("starts with", function()
    local starts_with = core.string_has_prefix

    it("prefix param is nil", function()
        local result = starts_with("abc test", nil)
        assert.is_false(result, "false must be returned on nil input")
    end)

    it("found prefix", function()
        local result = starts_with("abc test", "abc")
        assert.is_true(result, "prefix must be found")
    end)

    for _, str in ipairs {
        "test abc ",
        "test abcd",
    } do
        it("'abc' not prefix of '" .. str .. "'", function()
            local result = starts_with(str, "abc")
            assert.is_false(
                result,
                "prefix should not be found, string not in the end"
            )
        end)
    end
end)

describe("strip prefix", function()
    local strip_prefix = core.string_strip_prefix

    it("not in prefix", function()
        local result = strip_prefix("aaa abc", "abc")
        assert.are.equal(
            "aaa abc",
            result,
            "string is no in prefix, it's suffix"
        )
    end)

    it("not in string", function()
        local result = strip_prefix("aaa bbb", "abc")
        assert.are.equal("aaa bbb", result, "prefix should not be found in")
    end)

    it("remove prefix ", function()
        local result = strip_prefix("abc aaa", "abc")
        assert.are.equal(" aaa", result, "prefix was removed incorrectly")
    end)
end)

describe("array operation", function()
    local map = core.array_map

    describe("map", function()
        for name, case in pairs {
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
        } do
            it(name .. " list", function()
                local result = map(case.input, function(x)
                    return x * 2
                end)
                assert.is_true(vim.deep_equal(result, case.expected))
            end)
        end
    end)

    describe("filter", function()
        local filter = core.array_filter

        for name, case in pairs {
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
        } do
            it(name .. " list", function()
                local result = filter(case.input, function(x)
                    return x % 2 == 0
                end)
                assert.is_true(vim.deep_equal(result, case.expected))
            end)
        end
    end)

    describe("flat_map", function()
        local flat_map = core.array_flat_map

        for name, case in pairs {
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
        } do
            it(name .. " list", function()
                local result = flat_map(case.input, function(x)
                    return { x, x * 2 }
                end)
                assert.is_true(
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
