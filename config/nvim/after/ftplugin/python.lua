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

vim.api.nvim_buf_create_user_command(0, "PythonToggleTest", function()
    local cwf = vim.fn.expand "%:."
    if string.find(cwf, "test_.*%.py$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "test_(%w+)%.py$", "%1.py"))
    elseif string.find(cwf, "%.py$") then
        vim.fn.execute("edit " .. string.gsub(cwf, "(%w+)%.py$", "test_%1.py"))
    end
end, {
    desc = "toggle between test and source code",
})

vim.keymap.set("n", "<localleader>ot", "<cmd>PythonToggleTest<cr>", {
    desc = "toggle between test and source code",
    buffer = true,
})
