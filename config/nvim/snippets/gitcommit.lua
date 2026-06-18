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

local commit_types = {
    "feat",
    "fix",
    "refactor",
    "chore",
    "docs",
    "test",
    "style",
    "perf",
    "ci",
    "build",
    "revert",
}

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

local function add_scope(scopes, seen, scope)
    scope = vim.trim(scope or "")

    if scope == "" or seen[scope] then
        return
    end

    seen[scope] = true
    table.insert(scopes, scope)
end

local function path_scope(path)
    if vim.startswith(path, "config/nvim/") then
        return "nvim"
    elseif vim.startswith(path, "config/nvim-minimal/") then
        return "nvim"
    elseif vim.startswith(path, "config/opencode/") then
        return "opencode"
    elseif vim.startswith(path, "config/hammerspoon/") then
        return "hammerspoon"
    elseif vim.startswith(path, "config/wezterm/") then
        return "wezterm"
    elseif vim.startswith(path, "sh/setup/") then
        return "setup"
    elseif vim.startswith(path, "sh/") then
        return "shell"
    elseif vim.startswith(path, ".github/workflows/") then
        return "ci"
    elseif vim.startswith(path, "bin/") then
        return "bin"
    elseif vim.startswith(path, "tests/") then
        return "test"
    elseif path == "README.md" or path == "AGENTS.md" then
        return "docs"
    end

    return nil
end

local function add_staged_scopes(root, scopes, seen)
    local files = run_git(root, { "diff", "--cached", "--name-only" })
    if not files then
        return
    end

    for _, path in ipairs(vim.split(files, "\n", { trimempty = true })) do
        add_scope(scopes, seen, path_scope(path))
    end
end

local function add_history_scopes(root, scopes, seen)
    local subjects = run_git(root, { "log", "--format=%s", "--max-count=200" })
    if not subjects then
        return
    end

    for _, subject in ipairs(vim.split(subjects, "\n", { trimempty = true })) do
        add_scope(scopes, seen, string.match(subject, "^[a-z]+%(([^)]+)%)!?:"))
    end
end

local function git_scopes()
    local root = current_git_root()
    if not root then
        return {}
    end

    local scopes = {}
    local seen = {}

    add_staged_scopes(root, scopes, seen)
    add_history_scopes(root, scopes, seen)

    return scopes
end

local function commit_type_choice()
    local choices = {}

    for _, commit_type in ipairs(commit_types) do
        table.insert(choices, t(commit_type))
    end

    return c(1, choices)
end

local function scope_node(scope)
    if scope == "" then
        return sn(nil, { t "" })
    end

    return sn(nil, { t("(" .. scope .. ")") })
end

local function manual_scope_node()
    return sn(nil, { t "(", i(1, "scope"), t ")" })
end

local function commit_scope_choice()
    local choices = {}

    for _, scope in ipairs(git_scopes()) do
        table.insert(choices, scope_node(scope))
    end

    table.insert(choices, scope_node "")

    if #choices == 1 then
        table.insert(choices, manual_scope_node())
    end

    return sn(nil, { c(1, choices) })
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
        { trig = "cc", dscr = "Insert a conventional commit header" },
        fmt("{}{}: {}", {
            commit_type_choice(),
            d(2, commit_scope_choice),
            i(0, "summary"),
        })
    ),
    s(
        { trig = "coauth", dscr = "Insert a Co-authored-by trailer" },
        fmt("Co-authored-by: {}\n{}", {
            d(1, coauthor_choice),
            i(0),
        })
    ),
}
