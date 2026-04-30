local ts = require "nvim-treesitter"
local ts_pack = require("ts-pack")
local ts_select = require "nvim-treesitter-textobjects.select"
local ts_moves = require "nvim-treesitter-textobjects.move"
local ts_swaps = require "nvim-treesitter-textobjects.swap"
local ts_context = require "treesitter-context"
local ts_textobjects = require "nvim-treesitter-textobjects"

ts_pack.add({
  { name = "bash", src = "https://github.com/tree-sitter/tree-sitter-bash", version = "a06c2e4415e9bc0346c6b86d401879ffb44058f7", queries = "queries" },
  { name = "c", src = "https://github.com/tree-sitter/tree-sitter-c", version = "ae19b676b13bdcc13b7665397e6d9b14975473dd", queries = "queries" },
  { name = "clojure", src = "https://github.com/sogaiu/tree-sitter-clojure", version = "e43eff80d17cf34852dcd92ca5e6986d23a7040f", queries = "queries" },
  { name = "fennel", src = "https://github.com/alexmozaidze/tree-sitter-fennel", version = "3f0f6b24d599e92460b969aabc4f4c5a914d15a0" },
  { name = "go", src = "https://github.com/tree-sitter/tree-sitter-go", version = "2346a3ab1bb3857b48b29d779a1ef9799a248cd7", queries = "queries" },
  { name = "gomod", src = "https://github.com/camdencheek/tree-sitter-go-mod", version = "2e886870578eeba1927a2dc4bd2e2b3f598c5f9a", queries = "queries" },
  { name = "gosum", src = "https://github.com/tree-sitter-grammars/tree-sitter-go-sum", version = "27816eb6b7315746ae9fcf711e4e1396dc1cf237", queries = "queries" },
  { name = "groovy", src = "https://github.com/murtaza64/tree-sitter-groovy", version = "781d9cd1b482a70a6b27091e5c9e14bbcab3b768", queries = "queries" },
  { name = "java", src = "https://github.com/tree-sitter/tree-sitter-java", version = "e10607b45ff745f5f876bfa3e94fbcc6b44bdc11", queries = "queries" },
  { name = "javadoc", src = "https://github.com/rmuir/tree-sitter-javadoc", version = "e2f56b4d0df08f6ed5df8bae266f9e75b340a9ab", queries = "queries" },
  { name = "javascript", src = "https://github.com/tree-sitter/tree-sitter-javascript", version = "58404d8cf191d69f2674a8fd507bd5776f46cb11", queries = "queries" },
  { name = "kotlin", src = "https://github.com/fwcd/tree-sitter-kotlin", version = "93bfeee1555d2b1442d68c44b0afde2a3b069e46" },
  { name = "lua", src = "https://github.com/tree-sitter-grammars/tree-sitter-lua", version = "10fe0054734eec83049514ea2e718b2a56acd0c9" },
  { name = "luadoc", src = "https://github.com/tree-sitter-grammars/tree-sitter-luadoc", version = "873612aadd3f684dd4e631bdf42ea8990c57634e" },
  { name = "make", src = "https://github.com/tree-sitter-grammars/tree-sitter-make", version = "70613f3d812cbabbd7f38d104d60a409c4008b43" },
  { name = "proto", src = "https://github.com/coder3101/tree-sitter-proto", version = "d65a18ce7c2242801f702770114ad08056c7f8c9" },
  { name = "python", src = "https://github.com/tree-sitter/tree-sitter-python", version = "v0.25.0" },
  { name = "ruby", src = "https://github.com/tree-sitter/tree-sitter-ruby", version = "ad907a69da0c8a4f7a943a7fe012712208da6dee" },
  { name = "rust", src = "https://github.com/tree-sitter/tree-sitter-rust", version = "77a3747266f4d621d0757825e6b11edcbf991ca5" },
  { name = "scheme", src = "https://github.com/6cdh/tree-sitter-scheme", version = "c6cb7c7d7a04b3f5d999c28e2e9c0c31b2d50ece" },
  { name = "sql", src = "https://github.com/derekstride/tree-sitter-sql", version = "851e9cb257ba7c66cc8c14214a31c44d2f1e954e" },
  { name = "tsx", src = "https://github.com/tree-sitter/tree-sitter-typescript", version = "75b3874edb2dc714fb1fd77a32013d0f8699989f", location = "tsx" },
  { name = "typescript", src = "https://github.com/tree-sitter/tree-sitter-typescript", version = "75b3874edb2dc714fb1fd77a32013d0f8699989f", location = "typescript" },
  { name = "vim", src = "https://github.com/tree-sitter-grammars/tree-sitter-vim", version = "3092fcd99eb87bbd0fc434aa03650ba58bd5b43b" },
  { name = "vimdoc", src = "https://github.com/neovim/tree-sitter-vimdoc", version = "f061895a0eff1d5b90e4fb60d21d87be3267031a" },
  { name = "css", src = "https://github.com/tree-sitter/tree-sitter-css", version = "dda5cfc5722c429eaba1c910ca32c2c0c5bb1a3f" },
  { name = "html", src = "https://github.com/tree-sitter/tree-sitter-html", version = "73a3947324f6efddf9e17c0ea58d454843590cc0" },
  { name = "markdown", src = "https://github.com/tree-sitter-grammars/tree-sitter-markdown", version = "f969cd3ae3f9fbd4e43205431d0ae286014c05b5", location = "tree-sitter-markdown" },
  { name = "markdown_inline", src = "https://github.com/tree-sitter-grammars/tree-sitter-markdown", version = "f969cd3ae3f9fbd4e43205431d0ae286014c05b5", location = "tree-sitter-markdown-inline" },
  { name = "xml", src = "https://github.com/tree-sitter-grammars/tree-sitter-xml", version = "5000ae8f22d11fbe93939b05c1e37cf21117162d", location = "xml" },
  { name = "asm", src = "https://github.com/RubixDev/tree-sitter-asm", version = "839741fef4dab5128952334624905c82b40c7133" },
  { name = "typst", src = "https://github.com/uben0/tree-sitter-typst", version = "46cf4ded12ee974a70bf8457263b67ad7ee0379d" },
  { name = "dot", src = "https://github.com/rydesun/tree-sitter-dot", version = "80327abbba6f47530edeb0df9f11bd5d5c93c14d" },
  { name = "toml", src = "https://github.com/tree-sitter-grammars/tree-sitter-toml", version = "64b56832c2cffe41758f28e05c756a3a98d16f41" },
  { name = "yaml", src = "https://github.com/tree-sitter-grammars/tree-sitter-yaml", version = "4463985dfccc640f3d6991e3396a2047610cf5f8" },
  { name = "csv", src = "https://github.com/tree-sitter-grammars/tree-sitter-csv", version = "f6bf6e35eb0b95fbadea4bb39cb9709507fcb181", location = "csv" },
  { name = "json", src = "https://github.com/tree-sitter/tree-sitter-json", version = "001c28d7a29832b06b0e831ec77845553c89b56d" },
  { name = "json5", src = "https://github.com/Joakker/tree-sitter-json5", version = "aa630ef48903ab99e406a8acd2e2933077cc34e1" },
  { name = "diff", src = "https://github.com/tree-sitter-grammars/tree-sitter-diff", version = "2520c3f934b3179bb540d23e0ef45f75304b5fed" },
  { name = "disassembly", src = "https://github.com/ColinKennedy/tree-sitter-disassembly", version = "0229c0211dba909c5d45129ac784a3f4d49c243a" },
  { name = "dockerfile", src = "https://github.com/camdencheek/tree-sitter-dockerfile", version = "971acdd908568b4531b0ba28a445bf0bb720aba5" },
  { name = "git_config", src = "https://github.com/the-mikedavis/tree-sitter-git-config", version = "0fbc9f99d5a28865f9de8427fb0672d66f9d83a5" },
  { name = "git_rebase", src = "https://github.com/the-mikedavis/tree-sitter-git-rebase", version = "760ba8e34e7a68294ffb9c495e1388e030366188" },
  { name = "gitcommit", src = "https://github.com/gbprod/tree-sitter-gitcommit", version = "33fe8548abcc6e374feaac5724b5a2364bf23090" },
  { name = "gitignore", src = "https://github.com/shunsambongi/tree-sitter-gitignore", version = "f4685bf11ac466dd278449bcfe5fd014e94aa504" },
  { name = "http", src = "https://github.com/rest-nvim/tree-sitter-http", version = "db8b4398de90b6d0b6c780aba96aaa2cd8e9202c" },
  { name = "mermaid", src = "https://github.com/monaqa/tree-sitter-mermaid", version = "90ae195b31933ceb9d079abfa8a3ad0a36fee4cc" },
  { name = "printf", src = "https://github.com/tree-sitter-grammars/tree-sitter-printf", version = "ec4e5674573d5554fccb87a887c97d4aec489da7" },
  { name = "query", src = "https://github.com/tree-sitter-grammars/tree-sitter-query", version = "fc5409c6820dd5e02b0b0a309d3da2bfcde2db17" },
  { name = "ssh_config", src = "https://github.com/tree-sitter-grammars/tree-sitter-ssh-config", version = "71d2693deadaca8cdc09e38ba41d2f6042da1616" },
}, { async = true })


-- ts.install {
--     -- languages
--     "bash",
--     "c",
--     "clojure",
--     "fennel",
--     "go",
--     "gomod",
--     "gosum",
--     "groovy",
--     "java",
--     "javadoc",
--     "javascript",
--     "kotlin",
--     "lua",
--     "luadoc",
--     "make",
--     "proto",
--     "python",
--     "ruby",
--     "rust",
--     "scheme",
--     "sql",
--     "tsx",
--     "typescript",
--     "vim",
--     "vimdoc",
--     -- markup
--     "css",
--     "html",
--     "markdown",
--     "markdown_inline",
--     "xml",
--     "asm",
--     "typst",
--     -- config
--     "dot",
--     "toml",
--     "yaml",
--     -- data
--     "csv",
--     "json",
--     "json5",
--     -- utility
--     "diff",
--     "disassembly",
--     "dockerfile",
--     "git_config",
--     "git_rebase",
--     "gitcommit",
--     "gitignore",
--     "http",
--     "mermaid",
--     "printf",
--     "query",
--     "ssh_config",
-- }

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
