return {
    "christoomey/vim-tmux-navigator",
    {
        "ThePrimeagen/harpoon",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        lazy = true,
        keys = {
            "<leader>h",
            "gh",
            "gH",
            "[h",
            "]h",
        },
        config = function()
            require("harpoon").setup {}

            require("telescope").load_extension "harpoon"

            vim.keymap.set("n", "<leader>h", function()
                require("harpoon.ui").toggle_quick_menu()
            end, { desc = "toggle harpoon ui" })
            vim.keymap.set("n", "gh", function()
                local count = vim.v.count
                if count == 0 then
                    count = 1
                end
                require("harpoon.ui").nav_file(count)
            end, { desc = "go to harpoon entry" })
            vim.keymap.set("n", "gH", function()
                require("harpoon.mark").add_file()
            end, { desc = "add buffer into the harpoon" })
            vim.keymap.set("n", "]h", function()
                require("harpoon.ui").nav_next()
            end, { desc = "go to next harpoon buffer" })
            vim.keymap.set("n", "[h", function()
                require("harpoon.ui").nav_prev()
            end, { desc = "go to prev harpoon buffer" })
        end,
    },
}
