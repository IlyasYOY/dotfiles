local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local d = ls.dynamic_node
local sn = ls.snippet_node

local record_separator = string.char(30)
local field_separator = string.char(31)

local function run_git(path, args)
    local cmd = { "git", "-C", path }
    vim.list_extend(cmd, args)

    local result = vim.system(cmd, { text = true }):wait()
    if result.code ~= 0 then
        return nil
    end

    return result.stdout or ""
end

local function add_path(paths, path)
    if not path or path == "" or vim.tbl_contains(paths, path) then
        return
    end

    table.insert(paths, path)
end

local function add_dot_git_parent(paths, path)
    local current = path

    while current and current ~= "" do
        if vim.fn.fnamemodify(current, ":t") == ".git" then
            add_path(paths, vim.fn.fnamemodify(current, ":h"))
            return
        end

        local parent = vim.fn.fnamemodify(current, ":h")
        if parent == current then
            return
        end

        current = parent
    end
end

local function candidate_git_paths()
    local paths = {}
    add_path(paths, vim.fn.getcwd())

    local buffer_dir = vim.fn.expand "%:p:h"
    add_path(paths, buffer_dir)
    add_dot_git_parent(paths, buffer_dir)

    return paths
end

local function current_git_root()
    for _, path in ipairs(candidate_git_paths()) do
        local root = run_git(path, { "rev-parse", "--show-toplevel" })
        if root and vim.trim(root) ~= "" then
            return vim.trim(root)
        end
    end

    return nil
end

local function add_author(authors, seen, name, email)
    name = vim.trim(name or "")
    email = vim.trim(email or "")

    if name == "" or email == "" then
        return
    end

    local key = string.lower(email)
    if seen[key] then
        return
    end

    seen[key] = true
    table.insert(authors, string.format("%s <%s>", name, email))
end

local function split_record(record)
    local first_separator = string.find(record, field_separator, 1, true)
    if not first_separator then
        return nil
    end

    local second_separator =
        string.find(record, field_separator, first_separator + 1, true)
    if not second_separator then
        return nil
    end

    return string.sub(record, 1, first_separator - 1),
        string.sub(record, first_separator + 1, second_separator - 1),
        string.sub(record, second_separator + 1)
end

local function parse_coauthor_line(line)
    local trailer = vim.trim(line)
    local prefix = "co-authored-by:"

    if string.sub(string.lower(trailer), 1, #prefix) ~= prefix then
        return nil, nil
    end

    return string.match(
        vim.trim(string.sub(trailer, #prefix + 1)),
        "^(.-)%s*<([^>]+)>%s*$"
    )
end

local function parse_authors(log_output)
    local authors = {}
    local seen = {}

    for _, record in
        ipairs(
            vim.split(
                log_output,
                record_separator,
                { plain = true, trimempty = true }
            )
        )
    do
        local name, email, body = split_record(record)
        if name and email and body then
            add_author(authors, seen, name, email)

            for line in string.gmatch(body, "[^\r\n]+") do
                add_author(authors, seen, parse_coauthor_line(line))
            end
        end
    end

    return authors
end

local function git_authors()
    local root = current_git_root()
    if not root then
        return {}
    end

    local log_output = run_git(root, {
        "log",
        "--all",
        "--format=%x1e%aN%x1f%aE%x1f%B",
    })

    if not log_output then
        return {}
    end

    return parse_authors(log_output)
end

local function coauthor_choice()
    local choices = {}

    for _, author in ipairs(git_authors()) do
        table.insert(choices, sn(nil, { t(author) }))
    end

    if #choices == 0 then
        table.insert(
            choices,
            sn(nil, { i(1, "Alice Doe <alice@example.com>") })
        )
    end

    return sn(nil, { c(1, choices) })
end

return {
    s(
        { trig = "coauth", dscr = "Insert a Co-authored-by trailer" },
        fmt("Co-authored-by: {}\n{}", {
            d(1, coauthor_choice),
            i(0),
        })
    ),
}
