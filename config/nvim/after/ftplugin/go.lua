vim.opt_local.expandtab = false

vim.api.nvim_create_user_command(
    "GoRemoveUselessComments",
    [[%s/\/\/ \w* \.*$//gc]],
    {
        desc = "remove all comments repeating name of the struct",
    }
)

vim.api.nvim_create_user_command(
    "GoRenameMockeryOnWithExpect",
    [[%s/On("\(\w*\)", /EXPECT().\1(/gc]],
    {
        desc = "replace all mockery api with a new one",
    }
)
