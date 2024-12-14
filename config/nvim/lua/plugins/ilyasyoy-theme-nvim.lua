return {
    "IlyasYOY/theme.nvim",
    dependencies = {
        "tjdevries/colorbuddy.nvim",
    },
    lazy = false,
    priority = 1000,
    dev = true,
    config = function()
        vim.cmd.colorscheme "ilyasyoy"
    end,
}
