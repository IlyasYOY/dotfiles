vim.opt_local.expandtab = false
vim.opt_local.spell = true

vim.api.nvim_create_user_command(
    "GoRemoveUselessComments",
    [[%s/\/\/ \w* \.*$//gc]],
    {
        desc = "remove all comments repeating name of the struct",
    }
)

vim.api.nvim_create_user_command(
    "GoRenameMockeryRawMockWithNew",
    [[%s/&mocks\.\(\w*\){}/mocks.New\1(t)/gc]],
    {
        desc = "replace all mockery &mocks.Some with mocks.NewSome(t)",
    }
)

vim.api.nvim_create_user_command(
    "GoRenameMockeryOnWithExpect",
    [[%s/On("\(\w*\)", /EXPECT().\1(/gc]],
    {
        desc = "replace all mockery api with a new one",
    }
)

vim.api.nvim_create_user_command(
    "GoReplaceRequireWithSuiteRequire",
    [[%s/require\.\(\w*\)(\(\w*\).T(), /\2.Require().\1(/gc]],
    {
        desc = "replace require with suite require",
    }
)

vim.api.nvim_create_user_command(
    "GoReplaceAssertWithSuiteAssert",
    [[%s/assert\.\(\w*\)(\(\w*\).T(), /\2.\1(/gc]],
    {
        desc = "replace assert with suite assert",
    }
)
