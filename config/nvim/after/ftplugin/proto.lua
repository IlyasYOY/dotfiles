vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

vim.api.nvim_create_user_command(
    "ProtoAddJSONTag",
    [[%s/\(\w* \(\w*\) = \d\+\);/\1 [json_name = "\2"];/gc]],
    {
        desc = "adds json tag to fields",
    }
)
