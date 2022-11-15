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

-- Search commands 

map_normal("<leader>ff", "<cmd>Telescope find_files<CR>")
map_normal("<leader>fg", "<cmd>Telescope live_grep<CR>")

-- Terminal commands 

map("t", "<Esc>", "<C-\\><C-n>")

-- CoC commands

-- More here: https://github.com/neoclide/coc.nvim#example-vim-configuration
-- Interactive mode mappings 
map("i", "<C-space>", "coc#refresh()", { silent = true, expr = true })
-- Make <CR> to accept selected completion item or notify coc.nvim to format
-- <C-g>u breaks current undo, please make your own choice.
map("i", "<CR>", "coc#pum#visible() ? coc#pum#confirm() : \"\\<C-g>u\\<CR>\\<c-r>=coc#on_enter()\\<CR>\"", { silent = true, expr = true })

-- GoTo code navigation.
-- Go Def
map_normal("gd", "<Plug>(coc-definition)", { silent = true })
-- Go (type) DEF
map_normal("gD", "<Plug>(coc-type-definition)", { silent = true })
-- Go Impl 
map_normal("gi", "<Plug>(coc-implementation)", { silent = true })
-- Go Ref
map_normal("gr", "<Plug>(coc-references)", { silent = true })

-- Help
map_normal("<leader>h", ":call ShowDocumentation()<CR>", { silent = true })
map("i", "<C-s>", "<C-O>:call CocActionAsync('showSignatureHelp')<CR>")
map("i", "<C-p>", "coc#pum#visible() ? coc#pum#prev(1) : \"\\<C-p>\"", { silent = true, expr = true})

-- ReName.
map_normal("<leader>rn", "<Plug>(coc-rename)")

-- Formatting selected code.
-- Org Code 
map("x", "<leader>oc", " <Plug>(coc-format-selected)")
map_normal("<leader>oc ", "<Plug>(coc-format-selected)")
map_normal("<leader>oc", ":Format<CR>")
-- Org Import 
map_normal("<leader>oi", ":OR<CR>")
-- Org All 
map_normal("<leader>oa", ":OR<CR>:Format<CR>")

-- Apply AutoFix to problem on the current line.
-- Help
map_normal("<leader>H ", "<Plug>(coc-fix-current)")

-- Applying codeAction to the selected region.
-- Example: `<leader>aap` for current paragraph
-- Action
map("x", "<leader>a", "<Plug>(coc-codeaction-selected)")
map_normal("<leader>a ", "<Plug>(coc-codeaction-selected)")

-- Use CTRL-S for selections ranges.
-- Requires 'textDocument/selectionRange' support of language server.
map_normal("<C-s>", "<Plug>(coc-range-select)", { silent = true })
map("x", "<C-s>", "<Plug>(coc-range-select)", { silent = true })

-- Map function and class text objects
-- NOTE: Requires 'textDocument.documentSymbol' support from the language server.
map("x", "if", "<Plug>(coc-funcobj-i)")
map("o", "if", "<Plug>(coc-funcobj-i)")
map("x", "af", "<Plug>(coc-funcobj-a)")
map("o", "af", "<Plug>(coc-funcobj-a)")
map("x", "ic", "<Plug>(coc-classobj-i)")
map("o", "ic", "<Plug>(coc-classobj-i)")
map("x", "ac", "<Plug>(coc-classobj-a)")
map("o", "ac", "<Plug>(coc-classobj-a)")

-- Find symbol of current document.
map_normal("<leader>O", " :<C-u>CocList outline<CR>", { silent = true, nowait = true })
-- Search workspace symbols.
map_normal("<leader>S", " :<C-u>CocList -I symbols<CR>", { silent = true, nowait = true })
-- Show me the lists
map_normal("<leader>L", " :<C-u>CocList<CR>", { silent = true, nowait = true })
-- Show me the lists
map_normal("<leader>E", " :<C-u>CocCommand explorer<CR>", { silent = true, nowait = true })

-- Telekasten commands 

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
