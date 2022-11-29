local M = {}

-- Simple test function, writes error if it happens.
--- @param test_name string
--- @param runnable function()
local function test_case(test_name, runnable)
    local status, result = pcall(runnable)
    if status then
        print('Test case: "' .. test_name .. '" ok')
    else
        print('Test case: "' .. test_name .. '" failed with ' .. result)
    end
end

local core = require "functions/core"
local java = require "functions/java"

test_case("string split should work", function()
    local result = core.string_split("hello world", " ")

    assert(#result == 2, ("string splitted incorrectly, resulting %s"):format(#result))
end)

test_case("string split should work with default parameter", function()
    local result = core.string_split "hello world"

    assert(#result == 2, ("string splitted incorrectly, resulting %s"):format(#result))
end)

test_case("processing assert all", function()
    local test_string = [[
    assertTrue(x == y, "message");
    assertEquals(x, y);
    assertFalse(x != y);
    ]]

    local result = java.wrap_text_with_assert_all(test_string)

    local expected_string = [[
assertAll(
  () -> assertTrue(x == y, "message"),
  () -> assertEquals(x, y),
  () -> assertFalse(x != y)
);
]]
    assert(result == expected_string, ("wrong result '%s', expected '%s'"):format(result, expected_string))
end)
