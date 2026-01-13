vim.opt_local.spell = true
vim.opt_local.wrap = true
vim.opt_local.textwidth = 72
vim.opt_local.colorcolumn = "73"

local function setup_ai()
    vim.api.nvim_buf_create_user_command(0, "AIChatGitGenerateCommit", function()
        vim.cmd ".!git diff --no-ext-diff --cached | aichat --code --role \\%conventional-commit-message\\% "
    end, { desc = "Generate a conventional commit message from staged changes" })

    vim.keymap.set("n", "<localleader>gc", function()
        return ":AIChatGitGenerateCommit<CR>"
    end, {
        expr = true,
        buffer = true,
        desc = "Generate AI commit message",
    })
end

setup_ai()
