vim.opt_local.spell = true

require("cmp").setup.buffer {
    sources = require("cmp").config.sources(
        { { name = "git" } },
        { { name = "conventionalcommits" } },
        { { name = "buffer" } }
    ),
}

vim.keymap.set("n", "<localleader>gc", function()
    require("codecompanion").prompt "commit-inline"
end, {
    buffer = true,
})
