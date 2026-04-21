---
name: dotfiles-luasnip
description: Write or update LuaSnip snippets for this dotfiles repository
metadata:
  tags: luasnip, neovim, snippets, lua, dotfiles
---

## When to use

Use this skill when modifying or creating snippets in
`config/nvim/snippets/*.lua` for this repository.

## Snippet file locations

Snippets live in `config/nvim/snippets/<filetype>.lua`. Currently maintained
files:

- `go.lua` - Go snippets
- `java.lua` - Java snippets, including Mockito and AssertJ helpers
- `lua.lua` - Lua snippets
- `markdown.lua` - Markdown and Obsidian snippets

Each file returns a Lua table of snippets. If a file for the requested
filetype does not exist yet, create one following the conventions below.

## Standard header

Every snippet file should start with only the imports it actually uses:

```lua
local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local sn = ls.snippet_node
local rep = require("luasnip.extras").rep
```

## LuaSnip node quick reference

- `s(trig, nodes, opts?)` defines a snippet. `trig` can be a string or a table
  like `{ trig = ..., dscr = ... }`.
- `t("text")` inserts static text. Use `{ "line1", "line2" }` for multiline
  text.
- `i(n, "default?")` creates jump-stop `n` with optional placeholder text.
- `i(0)` is the final cursor position.
- `f(fn, { deps }, opts?)` computes text from other nodes.
- `c(n, { choices })` creates a choice node at jump-stop `n`.
- `sn(nil, { nodes })` groups nodes, commonly inside `c`.
- `rep(n)` mirrors jump-stop `n`.
- `fmt("template", { nodes })` fills `{}` placeholders left-to-right.

Rules:

- Jump indices restart at `1` inside every `sn`.
- Every snippet must have an `i(0)`, either explicitly or via the final
  placeholder in `fmt`.
- Prefer `fmt` for snippets with more than one placeholder.
- Prefer `rep` over `f` when just mirroring another insert node.
- Add a `dscr` field when the trigger is not self-explanatory.

## Treesitter-gated conditions

When a snippet should only appear in a specific context, gate it with both
`show_condition` and `condition` using the same Treesitter-backed predicate:

```lua
local in_test_fn = {
    show_condition = is_in_test_function,
    condition = is_in_test_function,
}

s("trun", fmt([[...]], { ... }), in_test_fn)
```

## Shared snippet helpers

`require("ilyasyoy.snippets")` exposes shared date helpers:

- `.current_date()` returns an `f` node producing today's date as `YYYY-MM-DD`
- `.yesterday_date()` returns the previous day in the same format
- `.tomorrow_date()` returns the next day in the same format

## Workflow

1. Read the target snippet file first and follow the surrounding conventions.
2. Append the new snippet inside the `return { ... }` table.
3. Keep the return table sorted by trigger name when practical.
4. Run `luacheck config/nvim/snippets/<filetype>.lua` and fix any warnings.
5. Run `stylua config/nvim/snippets/<filetype>.lua`.
6. Report what was added and the trigger or triggers to use it.

## Style reminders

- Follow `stylua.toml`: 4-space indentation, 80-column width, double quotes.
- Preserve the existing snippet style in the target file.
