vim.opt_local.spell = true

require("cmp").setup.buffer {
    sources = require("cmp").config.sources(
        { { name = "git" } },
        { { name = "conventionalcommits" } },
        { { name = "buffer" } }
    ),
}
