local mapping = require "functions/map"

local map_normal = mapping.map_normal

local telescope = require('telescope')

map_normal("<leader>ff", "<cmd>lua require'telescope.builtin'.find_files { find_command = {'rg', '--files', '--hidden', '-g', '!.git' }}<cr>")
map_normal("<leader>fg", "<cmd>Telescope live_grep<CR>")
