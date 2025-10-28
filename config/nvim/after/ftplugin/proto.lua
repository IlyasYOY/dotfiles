vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

vim.api.nvim_buf_create_user_command(
    0,
    "ProtoAddJSONTag",
    [[%s/\(\w* \(\w*\) = \d\+\);/\1 [json_name = "\2"];/gc]],
    {
        desc = "adds json tag to fields",
    }
)

vim.api.nvim_buf_create_user_command(
    0,
    "ProtoLint",
    "Dispatch -compiler=make protolint lint -reporter=unix %:.",
    {
        desc = "runs proto linter on current file"
    }
)

vim.api.nvim_buf_create_user_command(
    0,
    "ProtoLintBuf",
    "Dispatch -compiler=make buf lint %:.",
    {
        desc = "runs proto linter on current file"
    }
)
