return {
    {
        "tjdevries/colorbuddy.nvim",
        dependencies = {
            "ellisonleao/gruvbox.nvim",
        },
        config = function()
            vim.cmd "colorscheme gruvbox"
            local Color, colors, Group, groups, styles =
                require("colorbuddy").setup()

            Color.new("red", "#cc3333")
            Color.new("green", "#33cc33")

            Group.new("@markup.list.unchecked.markdown", colors.red, colors.none, styles.none)
            Group.new("@markup.list.checked.markdown", colors.green, colors.none, styles.none)
        end,
    },
}
