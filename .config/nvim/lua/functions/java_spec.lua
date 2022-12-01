describe("java tests", function()
    local java = require "functions/java"

    it("processing assert all", function()
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
end)
