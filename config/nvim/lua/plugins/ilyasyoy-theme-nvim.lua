return {
    "IlyasYOY/theme.nvim",
    dependencies = {
        "tjdevries/colorbuddy.nvim",
    },
    dev = true,
    config = function()
        vim.cmd.colorscheme "ilyasyoy"
    end,
}
