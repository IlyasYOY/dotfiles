local ts = require "nvim-treesitter"
local ts_select = require "nvim-treesitter-textobjects.select"
local ts_moves = require "nvim-treesitter-textobjects.move"
local ts_swaps = require "nvim-treesitter-textobjects.swap"
local ts_context = require "treesitter-context"
local ts_textobjects = require "nvim-treesitter-textobjects"

ts.install {
    -- languages
    "bash",
    "c",
    "clojure",
    "fennel",
    "go",
    "gomod",
    "gosum",
    "groovy",
    "java",
    "javadoc",
    "javascript",
    "kotlin",
    "lua",
    "luadoc",
    "make",
    "proto",
    "python",
    "ruby",
    "rust",
    "scheme",
    "sql",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    -- markup
    "css",
    "html",
    "markdown",
    "markdown_inline",
    "xml",
    "asm",
    "typst",
    -- config
    "dot",
    "toml",
    "yaml",
    -- data
    "csv",
    "json",
    "json5",
    -- utility
    "diff",
    "disassembly",
    "dockerfile",
    "git_config",
    "git_rebase",
    "gitcommit",
    "gitignore",
    "http",
    "mermaid",
    "printf",
    "query",
    "ssh_config",
}

vim.treesitter.language.register("javascript", "tsx")
vim.treesitter.language.register("typescript.tsc", "tsx")

-- nvim-treesitter-textobjects
vim.g.no_plugin_maps = true
ts_textobjects.setup {
    select = {
        lookahead = true,
        include_surrounding_whitespace = false,
    },
    move = {
        set_jumps = true,
    },
}

local function setup_selects()
    local buf_opts = { buffer = true }

    vim.keymap.set({ "o", "x" }, "=r", function()
        ts_select.select_textobject("@assignment.rhs", "textobjects")
    end, buf_opts)

    vim.keymap.set({ "o", "x" }, "aa", function()
        ts_select.select_textobject("@parameter.outer", "textobjects")
    end, buf_opts)
    vim.keymap.set({ "o", "x" }, "ia", function()
        ts_select.select_textobject("@parameter.inner", "textobjects")
    end, buf_opts)

    vim.keymap.set({ "o", "x" }, "ai", function()
        ts_select.select_textobject("@conditional.outer", "textobjects")
    end, buf_opts)
    vim.keymap.set({ "o", "x" }, "ii", function()
        ts_select.select_textobject("@conditional.inner", "textobjects")
    end, buf_opts)

    vim.keymap.set({ "o", "x" }, "af", function()
        ts_select.select_textobject("@function.outer", "textobjects")
    end, buf_opts)
    vim.keymap.set({ "o", "x" }, "if", function()
        ts_select.select_textobject("@function.inner", "textobjects")
    end, buf_opts)

    vim.keymap.set({ "o", "x" }, "at", function()
        ts_select.select_textobject("@class.outer", "textobjects")
    end, buf_opts)
    vim.keymap.set({ "o", "x" }, "it", function()
        ts_select.select_textobject("@class.inner", "textobjects")
    end, buf_opts)
end

local function setup_moves()
    local buf_opts = { buffer = true }

    vim.keymap.set({ "n", "o", "x" }, "]f", function()
        ts_moves.goto_next_start("@function.outer", "textobjects")
    end, buf_opts)
    vim.keymap.set({ "n", "o", "x" }, "]F", function()
        ts_moves.goto_next_end("@function.outer", "textobjects")
    end, buf_opts)

    vim.keymap.set({ "n", "o", "x" }, "[f", function()
        ts_moves.goto_previous_start("@function.outer", "textobjects")
    end, buf_opts)
    vim.keymap.set({ "n", "o", "x" }, "[F", function()
        ts_moves.goto_previous_end("@function.outer", "textobjects")
    end, buf_opts)
end

local function setup_swaps()
    local buf_opts = { buffer = true }

    vim.keymap.set("n", "<leader>man", function()
        ts_swaps.swap_next "@parameter.inner"
    end, buf_opts)
    vim.keymap.set("n", "<leader>map", function()
        ts_swaps.swap_previous "@parameter.inner"
    end, buf_opts)

    vim.keymap.set("n", "<leader>mfn", function()
        ts_swaps.swap_next "@function.inner"
    end, buf_opts)
    vim.keymap.set("n", "<leader>mfp", function()
        ts_swaps.swap_previous "@function.inner"
    end, buf_opts)
end

local ts_group = vim.api.nvim_create_augroup("ilyasyoy-treesitter", {})

vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "go",
        "gomod",
        "gosum",
        "java",
        "lua",
        "make",
        "markdown",
        "proto",
        "python",
        "query",
        "ruby",
        "sql",
        "javascript",
        "typescript",
        "typescriptreact",
        "typst",
        "vim",
        "yaml",
    },
    callback = function()
        vim.treesitter.start()

        setup_selects()
        setup_moves()
        setup_swaps()

        vim.opt_local.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

        vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.opt_local.foldmethod = "expr"

        vim.opt_local.foldcolumn = "1"
        vim.opt_local.foldlevel = 99
        vim.opt_local.foldlevelstart = 99
        vim.opt_local.foldenable = true
    end,
    group = ts_group,
})

ts_context.setup {
    enable = true,
    max_lines = 1,
    line_numbers = true,
}

vim.keymap.set("n", "[c", function()
    ts_context.go_to_context(vim.v.count1)
end, { silent = true })
