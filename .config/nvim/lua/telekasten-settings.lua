-- Telekasten settings

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