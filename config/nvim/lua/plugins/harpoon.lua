return {
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        lazy = true,
        keys = {
            "<leader>ha",
            "<leader>hA",
            "<leader>hr",
            "<leader>hh",
            "[h",
            "[H",
            "]h",
            "]H",
        },
        config = function()
            local harpoon = require "harpoon"

            harpoon:setup()

            vim.keymap.set("n", "<leader>ha", function()
                harpoon:list():prepend()
            end)
            vim.keymap.set("n", "<leader>hA", function()
                harpoon:list():append()
            end)
            vim.keymap.set("n", "<leader>hr", function()
                harpoon:list():remove()
            end)
            vim.keymap.set("n", "<leader>hh", function()
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end)

            vim.keymap.set("n", "]h", function()
                harpoon:list():next()
            end)
            vim.keymap.set("n", "[h", function()
                harpoon:list():prev()
            end)
            vim.keymap.set("n", "]H", function()
                harpoon:list():select(harpoon:list():length())
            end)
            vim.keymap.set("n", "[H", function()
                harpoon:list():select(1)
            end)
        end,
    },
}
