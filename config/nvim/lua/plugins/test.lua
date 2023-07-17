return {
    -- TODO: MAKE IT WORK!!!
    -- {
    --     "nvim-neotest/neotest",
    --     dependencies = {
    --         "nvim-neotest/neotest-vim-test",
    --         "nvim-neotest/neotest-plenary",
    --     },
    --     config = function()
    --         require("neotest").setup {
    --             adapters = {
    --                 require "neotest-plenary",
    --                 require "neotest-vim-test" {
    --                     ignore_file_types = { "lua" },
    --                 },
    --             },
    --         }
    --     end,
    -- },
    {
        "vim-test/vim-test",
        lazy = true,
        keys = {
            "<leader>t",
            "<leader>T",
        },
        config = function()
            vim.keymap.set(
                "n",
                "<leader>t",
                "<cmd>TestFile<cr>",
                { silent = true }
            )
            vim.keymap.set(
                "n",
                "<leader>T",
                "<cmd>TestSuite<cr>",
                { silent = true }
            )
        end,
    },
}
