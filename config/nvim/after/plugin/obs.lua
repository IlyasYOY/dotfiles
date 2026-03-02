local obs = require "obs"
obs.setup {
    vault_home = "~/Projects/IlyasYOY/notes-wiki",
    vault_name = "notes-wiki",
    journal = {
        daily_template_name = "daily",
        weekly_template_name = "weekly",
    },
}

vim.keymap.set("n", "<leader>nn", "<cmd>ObsNvimFollowLink<cr>")
vim.keymap.set("n", "<leader>nr", "<cmd>ObsNvimRandomNote<cr>")
vim.keymap.set("n", "<leader>nN", "<cmd>ObsNvimNewNote<cr>")
vim.keymap.set("n", "<leader>ny", "<cmd>ObsNvimCopyObsidianLinkToNote<cr>")
vim.keymap.set("n", "<leader>no", "<cmd>ObsNvimOpenInObsidian<cr>")
vim.keymap.set("n", "<leader>nd", "<cmd>ObsNvimDailyNote<cr>")
vim.keymap.set("n", "<leader>nw", "<cmd>ObsNvimWeeklyNote<cr>")
vim.keymap.set("n", "<leader>nrn", "<cmd>ObsNvimRename<cr>")
vim.keymap.set("n", "<leader>nT", "<cmd>ObsNvimTemplate<cr>")
vim.keymap.set("n", "<leader>nM", "<cmd>ObsNvimMove<cr>")
vim.keymap.set("n", "<leader>nb", "<cmd>ObsNvimBacklinks<cr>")
