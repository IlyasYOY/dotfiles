vim.opt_local.spell = true

require("cmp").setup.buffer {
    sources = require("cmp").config.sources(
        { { name = "git" } },
        { { name = "conventionalcommits" } },
        { { name = "buffer" } }
    ),
}

vim.api.nvim_buf_create_user_command(0, "AIChatGitGenerateCommit", function()
    vim.cmd ".!git diff --no-ext-diff --cached | aichat --code --role \\%conventional-commit-message\\% "
end, { desc = "Generate a conventional commit message from staged changes" })

vim.keymap.set("n", "<localleader>gc", function()
    return ":AIChatGitGenerateCommit<CR>"
end, {
    expr = true,
    desc = "Generate AI commit message",
})
