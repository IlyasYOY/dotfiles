vim.api.nvim_buf_create_user_command(0, "PythonTestAll", function(opts)
    vim.cmd.Dispatch { "pytest" }
end, {
    desc = "run test for all packages",
})

vim.keymap.set(
    "n",
    "<localleader>ta",
    "<cmd>PythonTestAll<cr>",
    { desc = "run test for all packages", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "PythonTestPackage", function(opts)
    vim.cmd.Dispatch {
        "pytest " .. vim.fn.expand "%:p:h",
    }
end, {
    desc = "run test for a package",
})

vim.keymap.set(
    "n",
    "<localleader>tp",
    "<cmd>PythonTestPackage<cr>",
    { desc = "run test for a package", buffer = true }
)

vim.api.nvim_buf_create_user_command(0, "PythonTestFile", function(opts)
    local cwf = vim.fn.expand "%:."
    vim.cmd.Dispatch { "pytest " .. cwf }
end, {
    desc = "run test for a file",
})

vim.keymap.set(
    "n",
    "<localleader>tt",
    "<cmd>PythonTestFile<cr>",
    { desc = "run test for a file", buffer = true }
)
