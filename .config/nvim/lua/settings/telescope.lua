
local mapping = require("functions/map")

local map_normal = mapping.map_normal

map_normal("<leader>ff", "<cmd>Telescope find_files<CR>")
map_normal("<leader>fg", "<cmd>Telescope live_grep<CR>")
