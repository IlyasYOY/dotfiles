vim.opt_local.spell = true
vim.opt_local.wrap = true
vim.bo.formatprg = "mdsf format --stdin --log-level=off"

vim.api.nvim_buf_create_user_command(0, "AIChatMDCreateTitle", function()
    local filename = vim.api.nvim_buf_get_name(0)
    local cmd = "cat "
        .. vim.fn.shellescape(filename)
        .. " | aichat --code --role %create-title%"

    local output = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 then
        vim.notify(
            "AIChat failed: " .. table.concat(output, "\n"),
            vim.log.levels.ERROR
        )
        return
    end

    local title = table.concat(output, "\n"):gsub("%s+$", "")

    vim.fn.setreg('"', title)

    vim.notify(
        "AI-generated title (" .. title .. ') copied to " register.',
        vim.log.levels.INFO
    )
end, {
    range = false,
    desc = "Create a title for the current markdown buffer using AIChat and copy it to the \" register",
})
