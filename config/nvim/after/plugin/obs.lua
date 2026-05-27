require("obs").setup {
    vault_home = "~/Projects/IlyasYOY/notes-wiki",
    vault_name = "notes-wiki",
    journal = {
        daily_template_name = "daily",
        weekly_template_name = "weekly",
    },
}

vim.keymap.set(
    "n",
    "<leader>nn",
    "<cmd>ObsNvimFollowLink<cr>",
    { desc = "Follow note link" }
)
vim.keymap.set(
    "n",
    "<leader>nr",
    "<cmd>ObsNvimRandomNote<cr>",
    { desc = "Random note" }
)
vim.keymap.set(
    "n",
    "<leader>nN",
    "<cmd>ObsNvimNewNote<cr>",
    { desc = "New note" }
)
vim.keymap.set(
    "n",
    "<leader>ny",
    "<cmd>ObsNvimCopyObsidianLinkToNote<cr>",
    { desc = "Copy Obsidian link" }
)
vim.keymap.set(
    "n",
    "<leader>no",
    "<cmd>ObsNvimOpenInObsidian<cr>",
    { desc = "Open in Obsidian" }
)
vim.keymap.set(
    "n",
    "<leader>nd",
    "<cmd>ObsNvimDailyNote<cr>",
    { desc = "Daily note" }
)
vim.keymap.set(
    "n",
    "<leader>nD",
    "<cmd>ObsNvimDailyNote!<cr>",
    { desc = "Daily note calendar" }
)
vim.keymap.set(
    "n",
    "<leader>nw",
    "<cmd>ObsNvimWeeklyNote<cr>",
    { desc = "Weekly note" }
)
vim.keymap.set(
    "n",
    "<leader>nrn",
    "<cmd>ObsNvimRename<cr>",
    { desc = "Rename note" }
)
vim.keymap.set(
    "n",
    "<leader>nT",
    "<cmd>ObsNvimTemplate<cr>",
    { desc = "Apply template" }
)
vim.keymap.set(
    "n",
    "<leader>nM",
    "<cmd>ObsNvimMove<cr>",
    { desc = "Move note" }
)
vim.keymap.set(
    "n",
    "<leader>nb",
    "<cmd>ObsNvimBacklinks<cr>",
    { desc = "Show backlinks" }
)

local obs_group = vim.api.nvim_create_augroup("ilyasyoy-obs", {})

vim.api.nvim_create_autocmd("FileType", {
    group = obs_group,
    pattern = "markdown",
    callback = function(args)
        vim.keymap.set("n", "]l", function()
            vim.cmd(vim.v.count1 .. "ObsNvimNextLink!")
        end, { buffer = args.buf, desc = "Next link" })
        vim.keymap.set("n", "[l", function()
            vim.cmd(vim.v.count1 .. "ObsNvimPrevLink!")
        end, { buffer = args.buf, desc = "Previous link" })
        vim.keymap.set("n", "]L", function()
            vim.cmd(vim.v.count1 .. "ObsNvimNextLink")
        end, { buffer = args.buf, desc = "Next wiki link" })
        vim.keymap.set("n", "[L", function()
            vim.cmd(vim.v.count1 .. "ObsNvimPrevLink")
        end, { buffer = args.buf, desc = "Previous wiki link" })
    end,
})
