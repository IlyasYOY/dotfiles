return {
    {
        "tjdevries/colorbuddy.nvim",
        config = function()
            vim.cmd "colorscheme gruvbox"
            local Color, colors, Group, groups, styles =
                require("colorbuddy").setup()

            Color.new("red", "#cc3333")
            Color.new("green", "#33cc33")

            Group.new("@text.todo.unchecked", colors.red, nil, styles.bold)
            Group.new("@text.todo.checked", colors.green, nil, styles.bold)
        end,
    },
}
