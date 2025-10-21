
vim.api.nvim_create_user_command("AIChatCodeEdit", function(opts)
    vim.cmd("'<,'>!aichat --code --role \\%nvim-code-edit\\% " .. opts.args)
end, {
    range = true,
    nargs = 1,
    desc = "Run AIChat code edit on the selected range with the provided arguments",
})

vim.keymap.set("v", "<leader>ce", function()
    local prompt = vim.fn.input "Write a prompt: "
    return ":AIChatCodeEdit " .. prompt .. "<CR>"
end, {
    expr = true,
    desc = "Edit code via AIChat",
})

vim.api.nvim_create_user_command(
    "AIChatFixGrammar",
    "'<'>!aichat --code --role \\%fix-grammar\\%",
    {
        range = true,
        desc = "Fix grammar using AIChat",
    }
)
