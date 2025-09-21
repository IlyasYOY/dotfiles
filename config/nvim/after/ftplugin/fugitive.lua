vim.keymap.set("n", "dt", ":Gtabedit <Plug><cfile><Bar>Gvdiffsplit<CR>", {
    buffer = true,
})

vim.keymap.set(
    "n",
    "<localleader>rs",
    [[<cmd>execute ':Git reset --soft ' . expand('<cWORD>') <CR>]],
    {
        buffer = true,
    }
)

vim.api.nvim_buf_create_user_command(
    0,
    "AIChatGitReviewUnstaged",
    function(opts)
        vim.cmd "tabnew | r!git diff --no-ext-diff | aichat --code --role \\%diff-comments\\% "
        vim.opt.filetype = "markdown"
    end,
    {
        range = true,
        desc = "Review unstaged changes with AI Chat",
    }
)

vim.api.nvim_buf_create_user_command(0, "AIChatGitReviewStaged", function(opts)
    vim.cmd "tabnew | r!git diff --no-ext-diff --cached | aichat --code --role \\%diff-comments\\% "
    vim.opt.filetype = "markdown"
end, { range = true, desc = "Review staged changes with AI Chat" })
