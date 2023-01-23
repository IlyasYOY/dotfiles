local git_link = require "git-link"

vim.api.nvim_create_user_command("GitRemoteCopyRepoLink", function()
    git_link.copy_repo_link()
end, {
    desc = "Copies a link to currently working repository into the clipboard",
})

vim.api.nvim_create_user_command("GitRemoteCopyRepoLinkToFile", function()
    git_link.copy_repo_link_to_file()
end, {
    desc = "Copies a link to currently working file into the clipboard",
})

vim.api.nvim_create_user_command("GitRemoteCopyRepoLinkToLine", function()
    git_link.copy_repo_link_to_line()
end, {
    desc = "Copies a link to currently working line into the clipboard",
})
