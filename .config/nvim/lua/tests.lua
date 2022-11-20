local M = {}

local function test_case(test_name, runnable)
    local status, result = pcall(runnable)
    if status then
        print('Test case: "' .. test_name .. '" ok')
    else
        print('Test case: "' .. test_name .. '" failed with ' .. result)
    end
end

local core = require("core-functions")

test_case("string split should work", function()
    local result = core.string_split("hello world", " ")

    assert(#result == 2, ("string splitted incorrectly, resulting %s"):format(#result))
end)

test_case("string split should work with default parameter", function()
    local result = core.string_split("hello world")

    assert(#result == 2, ("string splitted incorrectly, resulting %s"):format(#result))
end)

test_case("convert to indexable array", function()
    local test_table = {}
    table.insert(test_table, 10)
    table.insert(test_table, 12)
    table.insert(test_table, 14)

    local result = core.to_indexed_array(test_table)

    assert(#result == 3, ("string splitted incorrectly, resulting %s"):format(#result))

    local first = result[0]
    local second = result[1]
    local third = result[2]
    assert(first == 10, "First element does not match")
    assert(second == 12, "Second element does not match")
    assert(third == 14, "Third element does not match")
end)
