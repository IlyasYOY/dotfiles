vim.cmd("source ~/.vimrc")

-- Functional wrapper for mapping custom keybindings
local function map(mode, alias, command, custom_options)
    local default_options = { noremap = true }
    if custom_options then
        default_options = vim.tbl_extend("force", default_options, custom_options)
        if default_options == nil then
            print("Cannot map mode:" .. mode .. " alias:" .. alias .. " for:" .. command .. " options:" .. custom_options)
            return
        end
    end
    vim.api.nvim_set_keymap(mode, alias, command, default_options)
end

local function map_normal(lhs, rhs, opts)
    map("n", lhs, rhs, opts)
end

map_normal("<leader>ff", "<cmd>Telescope find_files<cr>")
map_normal("<leader>fg", "<cmd>Telescope live_grep<cr>")

map("t", "<Esc>", "<C-\\><C-n>")

-- Telekasten settings 

map_normal("<leader>z", "<cmd>Telekasten<CR>")

map_normal("<leader>zb", "<cmd>Telekasten show_backlinks<CR>")
map_normal("<leader>zt", "<cmd>Telekasten show_tags<CR>")
map_normal("<leader>zz", "<cmd>Telekasten follow_link<CR>")
map_normal("<leader>zl", "<cmd>Telekasten insert_link<CR>")
map_normal("<leader>zn", "<cmd>Telekasten new_note<CR>")

map_normal("<leader>zd", "<cmd>Telekasten goto_today<CR>")
map_normal("<leader>zw", "<cmd>Telekasten goto_thisweek<CR>")
map_normal("<leader>zc", "<cmd>Telekasten show_calendar<CR>")

map_normal("<leader>zrn", "<cmd>Telekasten rename_note<CR>")

map_normal("<leader>zff", "<cmd>Telekasten find_notes<CR>")
map_normal("<leader>zfg", "<cmd>Telekasten search_notes<CR>")

local wiki_home = vim.fn.expand("~/vimwiki")
local diary_home = wiki_home .. "/" .. "diary"
local templates_home = wiki_home .. "/meta/templates"

require("telekasten").setup({
    home                        = wiki_home,
    take_over_my_home           = true,
    auto_set_filetype           = true,
    dailies                     = diary_home,
    weeklies                    = diary_home,
    templates                   = templates_home,
    image_subdir                = nil,
    extension                   = ".md",
    new_note_filename           = "uuid-title",
    uuid_type                   = "%Y-%m-%d %H%M%S",
    uuid_sep                    = "-",
    follow_creates_nonexisting  = true,
    dailies_create_nonexisting  = true,
    weeklies_create_nonexisting = true,
    journal_auto_open           = false,
    template_new_note           = templates_home .. "/zettel template.md",
    template_new_daily          = templates_home .. "/daily template.md",
    template_new_weekly         = templates_home .. "/weekly template.md",
    image_link_style            = "wiki",
    sort                        = "filename",
    plug_into_calendar          = true,
    calendar_opts               = {
        weeknm = 1,
        calendar_monday = 1,
        calendar_mark = "left-fit",
    },
    close_after_yanking         = false,
    insert_after_inserting      = true,
    tag_notation                = "#tag",
    command_palette_theme       = "ivy",
    show_tags_theme             = "ivy",
    subdirs_in_links            = false,
    template_handling           = "prefer_new_note",
    new_note_location           = "prefer_home",
    rename_update_links         = true,
    media_previewer             = "telescope-media-files",
})
