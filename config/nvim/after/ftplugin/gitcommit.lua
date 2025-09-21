vim.opt_local.spell = true

require("cmp").setup.buffer {
    sources = require("cmp").config.sources(
        { { name = "git" } },
        { { name = "conventionalcommits" } },
        { { name = "buffer" } }
    ),
}

vim.keymap.set("n", "<localleader>gc", function()
    return ":r!git diff --no-ext-diff --staged | aichat --code --role \\%conventional-commit-message\\%<CR>"
end, {
    expr = true,
})
