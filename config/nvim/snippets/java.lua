local ls = require "luasnip"
local ilyasyoy_snippets = require "ilyasyoy.snippets"

local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node

local function create_package()
    return f(function()
        local core = require "coredor"

        local file_dir = core.current_working_file_dir()
        local splitted = core.string_split(file_dir, "/java/")
        local package_dir = splitted[#splitted]
        if not package_dir then
            return ""
        end

        return string.gsub(package_dir, "/", ".")
    end)
end

return {
    s("today", ilyasyoy_snippets.current_date()),
    s(
        "package",
        fmt("package {};", {
            create_package(),
        })
    ),
    s(
        "mockvernmi",
        fmt("Mockito.verifyNoMoreInteractions({});", {
            i(0, "mock"),
        })
    ),
    s(
        "mockverni",
        fmt("Mockito.verifyNoInteractions({});", {
            i(0, "mock"),
        })
    ),
    s(
        "mockret",
        fmt("Mockito.doReturn({}).when({}).{};", {
            i(0, "value"),
            i(1, "mock"),
            i(2, "method"),
        })
    ),
    s(
        "mockthr",
        fmt("Mockito.doThrow({}).when({}).{};", {
            i(0, "exception"),
            i(1, "mock"),
            i(2, "method"),
        })
    ),
    s(
        "mockvero",
        fmt("Mockito.verify({}, Mockito.only()).{};", {
            i(1, "mock"),
            i(0, "method"),
        })
    ),
    s(
        "mockver",
        fmt("Mockito.verify({}).{};", {
            i(1, "mock"),
            i(0, "method"),
        })
    ),
    s(
        "assjc",
        fmt("AssertionsForClassTypes.assertThat({}).isNotNull();", {
            i(0, "actual"),
        })
    ),
    s(
        "assji",
        fmt("AssertionsForInterfaceTypes.assertThat({}).isNotNull();", {
            i(0, "actual"),
        })
    ),
    s(
        "assjnthr",
        fmt(
            "AssertionsForClassTypes.assertThatNoException().isThrownBy(() -> {});",
            {
                i(0, "callable"),
            }
        )
    ),
    s(
        "assjthr",
        fmt("AssertionsForClassTypes.assertThatThrownBy(() -> {});", {
            i(0, "callable"),
        })
    ),
    s(
        "assa",
        fmt('Assertions.assertAll("{}", () -> {});', {
            i(1, "header"),
            i(0, "assertion"),
        })
    ),
    s(
        "assnn",
        fmt('Assertions.assertNotNull({}, "{}");', {
            i(1, "actual"),
            i(0, "message"),
        })
    ),
    s(
        "assn",
        fmt('Assertions.assertNull({}, "{}");', {
            i(1, "actual"),
            i(0, "message"),
        })
    ),
    s(
        "assf",
        fmt('Assertions.assertFalse({}, "{}");', {
            i(1, "actual"),
            i(0, "message"),
        })
    ),
    s(
        "asst",
        fmt('Assertions.assertTrue({}, "{}");', {
            i(1, "actual"),
            i(0, "message"),
        })
    ),
    s(
        "asse",
        fmt('Assertions.assertEquals({}, {}, "{}");', {
            i(1, "expected"),
            i(2, "actual"),
            i(0, "message"),
        })
    ),
    s(
        "asss",
        fmt('Assertions.assertSame({}, {}, "{}");', {
            i(1, "expected"),
            i(2, "actual"),
            i(0, "message"),
        })
    ),
    s(
        "assthr",
        fmt('Assertions.assertThrows({}, () -> {}, "{}");', {
            i(1, "exception"),
            i(2, "throwing"),
            i(0, "message"),
        })
    ),
    s(
        "assnthr",
        fmt('Assertions.assertDoesNotThrow(() -> {}, "{}");', {
            i(1, "not throwing"),
            i(0, "message"),
        })
    ),
    s(
        "svrc",
        fmt('StepVerifier.create({}){}.verifyComplete();', {
            i(1, "actual"),
            i(0, ""),
        })
    ),
}
