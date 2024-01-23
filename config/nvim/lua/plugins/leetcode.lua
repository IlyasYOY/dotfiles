return {
    "kawre/leetcode.nvim",
    -- lazy = true,
    -- cmd = "Leet",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    config = function()
        local Path = require "plenary.path"
        local leetcode_dir = Path.path.home .. "/Projects/leetcode/"

        require("leetcode").setup {
            ---@type lc.lang
            lang = "golang",
            ---@type string
            directory = leetcode_dir,
            ---@type boolean
            logging = true,
            injector = {}, ---@type table<lc.lang, lc.inject>
            console = {
                open_on_runcode = true, ---@type boolean
                dir = "row", ---@type lc.direction
                size = { ---@type lc.size
                    width = "90%",
                    height = "75%",
                },
                result = {
                    size = "60%", ---@type lc.size
                },
                testcase = {
                    virt_text = true, ---@type boolean
                    size = "40%", ---@type lc.size
                },
            },
            description = {
                position = "left", ---@type lc.position
                width = "40%", ---@type lc.size
                show_stats = true, ---@type boolean
            },
            keys = {
                toggle = { "q", "<Esc>" }, ---@type string|string[]
                confirm = { "<CR>" }, ---@type string|string[]

                reset_testcases = "r", ---@type string
                use_testcase = "U", ---@type string
                focus_testcases = "H", ---@type string
                focus_result = "L", ---@type string
            },
        }
    end,
}
