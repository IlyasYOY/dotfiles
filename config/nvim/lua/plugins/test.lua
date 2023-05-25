return {
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
                "<cmd>TestNearest<cr>",
                { silent = true }
            )
            vim.keymap.set(
                "n",
                "<leader>T",
                "<cmd>TestFile<cr>",
                { silent = true }
            )
            -- nmap <silent> <leader>t :TestNearest<CR>
            -- nmap <silent> <leader>T :TestFile<CR>
            -- nmap <silent> <leader>a :TestSuite<CR>
            -- nmap <silent> <leader>l :TestLast<CR>
            -- nmap <silent> <leader>g :TestVisit<CR>
        end,
    },
}
