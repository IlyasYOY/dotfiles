vim.keymap.set(
    "n",
    "<leader>gg",
    ":Gedit :<CR>",
    { desc = "Open fugitive UI window", silent = true }
)

vim.keymap.set(
    "n",
    "<leader>gps",
    ":Git push<CR>",
    { desc = "Pushes changes to remote" }
)
vim.keymap.set(
    "n",
    "<leader>gpl",
    ":Git pull<CR>",
    { desc = "Pulls changes from remote" }
)

vim.keymap.set(
    "n",
    "<leader>gy",
    ":.GBrowse!<cr>",
    { desc = "Copy link to current line" }
)
vim.keymap.set(
    "n",
    "<leader>gY",
    ":GBrowse!<CR>",
    { desc = "Copy link to file" }
)
vim.keymap.set(
    "x",
    "<leader>gy",
    ":'<'>GBrowse!<cr>",
    { desc = "Copy link to current lines" }
)

vim.keymap.set(
    { "n", "v", "s" },
    "<leader>gb",
    ":Git blame<cr>",
    { desc = "Open blame" }
)

vim.keymap.set(
    { "n", "v", "s" },
    "<leader>gl",
    ":Gclog<cr>",
    { desc = "Open history for repo or selection" }
)

vim.keymap.set(
    { "n" },
    "<leader>gL",
    ":Gclog %<cr>",
    { desc = "Open history for the selected buffer" }
)

local fugitive_group = vim.api.nvim_create_augroup("ilyasyoy-fugitive", {})

vim.api.nvim_create_autocmd("FileType", {
    group = fugitive_group,
    pattern = { "git", "fugitive" },
    callback = function(args)
        vim.keymap.set(
            "n",
            "<localleader>rs",
            [[<cmd>execute ':Git reset --soft ' . expand('<cWORD>') <CR>]],
            {
                desc = "soft reset to revision under cursor",
                buffer = args.buf,
            }
        )
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = fugitive_group,
    pattern = "fugitive",
    callback = function(args)
        vim.keymap.set(
            "n",
            "dt",
            ":Gtabedit <Plug><cfile><Bar>Gvdiffsplit<CR>",
            {
                desc = "diff revision under cursor in a new tab",
                buffer = args.buf,
            }
        )

        vim.keymap.set("n", "cc", [[<cmd>Git commit --verbose <CR>]], {
            desc = "commit verbosely",
            buffer = args.buf,
        })
    end,
})
