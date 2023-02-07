return {
    {
        "nvim-lua/plenary.nvim",
        dev = true,
        config = function()
            vim.keymap.set("n", "<leader><leader>t", "<Plug>PlenaryTestFile", {
                desc = "Runs Plenary [t]ests for file",
            })

            vim.keymap.set(
                "n",
                "<leader><leader>T",
                -- NOTE: Default is {sequential=false}.
                -- I have helpers for test dirs which cause problems in concurrent env.
                -- Should I fix it?
                "<cmd>PlenaryBustedDirectory . {sequential=true}<CR>",
                {
                    desc = "Runs Plenary [T]ests in cwd",
                }
            )
        end,
    },
    { "IlyasYOY/coredor.nvim", dev = true },
}
