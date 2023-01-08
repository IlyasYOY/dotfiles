local git = require "functions.git"
local core = require "functions.core"

vim.keymap.set(
    "n",
    "<leader>g",
    ":Neogit<CR>",
    { desc = "Open neo[g]it UI window" }
)

local function resolve_repo_url()
    local first_remote = git.get_first_remote()
    if not first_remote then
        vim.notify "Unable to find remote url"
        return nil
    end

    local url = git.get_remote_url(first_remote)
    if url == nil then
        vim.notify "Unable to find remote url"
        return nil
    end

    local link = git.url_to_link(url)
    if link == nil then
        vim.notify("Unable to parse " .. url .. " to link")
        return nil
    end

    return link
end

vim.api.nvim_create_user_command("GitRemoteCopyRepoLink", function()
    local link = resolve_repo_url()
    if not link then
        return
    end

    vim.notify("Resolved link: " .. link)
    core.save_to_exchange_buffer(link)
end, {
    desc = "Copies a link to currently working repository into the clipboard",
})

vim.api.nvim_create_user_command("GitRemoteCopyRepoLinkToFile", function()
    local repo_link = resolve_repo_url()
    if not repo_link then
        return
    end

    local branch = git.current_branch()
    if not branch then
        vim.notify "Unable to find branch"
        return
    end

    local current_file = core.current_working_file()
    local file_link = git.resolve_link_to_current_working_file(
        repo_link,
        branch,
        current_file
    )

    vim.notify("Resolved link: " .. file_link)
    core.save_to_exchange_buffer(file_link)
end, {
    desc = "Copies a link to currently working file into the clipboard",
})

vim.api.nvim_create_user_command("GitRemoteCopyRepoLinkToLine", function()
    local repo_link = resolve_repo_url()
    if not repo_link then
        return
    end

    local branch = git.current_branch()
    if not branch then
        vim.notify "Unable to find branch"
        return
    end

    local current_file = core.current_working_file()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local line_link = git.resolve_link_to_current_line(
        repo_link,
        branch,
        current_file,
        current_line
    )

    vim.notify("Resolved link: " .. line_link)
    core.save_to_exchange_buffer(line_link)
end, {
    desc = "Copies a link to currently working line into the clipboard",
})