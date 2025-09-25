vim.opt_local.spell = true
vim.opt_local.wrap = true

vim.api.nvim_buf_create_user_command(0, "AIChatMDCreateTitle", function()
    vim.cmd "r ! cat % | aichat --code --role \\%create-title\\%"
end, {
    range = true,
    desc = "Create a title for the current markdown buffer using AIChat",
})
