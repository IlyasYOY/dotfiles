local mapping = require "functions/map"

local map_normal = mapping.map_normal

local telescope = require('telescope')

telescope.setup {
    defaults = { file_ignore_patterns = { "node_modules", ".git" } },
    pickers = {
        find_files = {
            hidden = true
        },
        live_grep = {
            additional_args = function(opts)
                return { "--hidden", "-g", "!.git" }
            end
        },
    },
}

map_normal("<leader>ff", "<cmd>Telescope find_files<cr>")
map_normal("<leader>fg", "<cmd>Telescope live_grep<CR>")
