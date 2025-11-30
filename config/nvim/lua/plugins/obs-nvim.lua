return {
    {
        "IlyasYOY/obs.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        lazy = true,
        dev = true,
        cmd = {
            "ObsNvimFollowLink",
            "ObsNvimRandomNote",
            "ObsNvimNewNote",
            "ObsNvimCopyObsidianLinkToNote",
            "ObsNvimOpenInObsidian",
            "ObsNvimDailyNote",
            "ObsNvimWeeklyNote",
            "ObsNvimRename",
            "ObsNvimTemplate",
            "ObsNvimMove",
            "ObsNvimBacklinks",
        },
        keys = {
            "<leader>nn",
            "<leader>nr",
            "<leader>nN",
            "<leader>ny",
            "<leader>no",
            "<leader>nd",
            "<leader>nw",
            "<leader>nrn",
            "<leader>nT",
            "<leader>nM",
            "<leader>nb",
        },
        config = function()
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
            vim.keymap.set(
                "n",
                "<leader>ny",
                "<cmd>ObsNvimCopyObsidianLinkToNote<cr>"
            )
            vim.keymap.set("n", "<leader>no", "<cmd>ObsNvimOpenInObsidian<cr>")
            vim.keymap.set("n", "<leader>nd", "<cmd>ObsNvimDailyNote<cr>")
            vim.keymap.set("n", "<leader>nw", "<cmd>ObsNvimWeeklyNote<cr>")
            vim.keymap.set("n", "<leader>nrn", "<cmd>ObsNvimRename<cr>")
            vim.keymap.set("n", "<leader>nT", "<cmd>ObsNvimTemplate<cr>")
            vim.keymap.set("n", "<leader>nM", "<cmd>ObsNvimMove<cr>")
            vim.keymap.set("n", "<leader>nb", "<cmd>ObsNvimBacklinks<cr>")
        end,
    },
}
