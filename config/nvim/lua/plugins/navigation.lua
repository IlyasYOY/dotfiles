return {
    {
        "ThePrimeagen/harpoon",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        lazy = true,
        keys = {
            "<leader>hh",
            "<leader>hg",
            "<leader>ha",
            "[h",
            "]h",
        },
        config = function()
            require("harpoon").setup {}

            require("telescope").load_extension "harpoon"

            vim.keymap.set("n", "<leader>hh", function()
                require("harpoon.ui").toggle_quick_menu()
            end)
            vim.keymap.set("n", "<leader>hg", function()
                local count = vim.v.count
                if count == 0 then
                    count = 1
                end
                require("harpoon.ui").nav_file(count)
            end)
            vim.keymap.set("n", "<leader>ha", function()
                require("harpoon.mark").add_file()
            end)
            vim.keymap.set("n", "]h", function()
                require("harpoon.ui").nav_next()
            end)
            vim.keymap.set("n", "[h", function()
                require("harpoon.ui").nav_prev()
            end)
        end,
    },
}
