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
map("i", "<CR>", "coc#pum#visible() ? coc#pum#confirm() : \"\\<C-g>u\\<CR>\\<c-r>=coc#on_enter()\\<CR>\"",
    { silent = true, expr = true })

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
vim.keymap.set("n", "<leader>h", function()
    if vim.bo.filetype == "vim" then
        vim.api.nvim_command("h " .. vim.expand("<cword>"))
        return
    elseif vim.fn["CocAction"]("hasProvider", "hover") then
        vim.fn["CocAction"]("doHover")
    else
        print("No help found")
    end
end, { silent = true })
map("i", "<C-s>", "<C-O>:call CocActionAsync('showSignatureHelp')<CR>")
map("i", "<C-p>", "coc#pum#visible() ? coc#pum#prev(1) : \"\\<C-p>\"", { silent = true, expr = true })

-- ReName.
map_normal("<leader>rn", "<Plug>(coc-rename)")

-- Formatting selected code.
-- Org Code
map("x", "<leader>oc", " <Plug>(coc-format-selected)")
map_normal("<leader>oc ", "<Plug>(coc-format-selected)")
map_normal("<leader>oc", "<cmd>Format<CR>")
-- Org Import
map_normal("<leader>oi", "<cmd>OR<CR>")
-- Org All
map_normal("<leader>oa", "<cmd>OR<CR><cnd>Format<CR>")

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
map_normal("<leader>O", "<cmd>CocList outline<CR>", { silent = true, nowait = true })
-- Search workspace symbols.
map_normal("<leader>S", "<cmd>CocList -I symbols<CR>", { silent = true, nowait = true })
-- Show me the lists
map_normal("<leader>L", "<cmd>CocList<CR>", { silent = true, nowait = true })
-- Show me the lists
map_normal("<leader>E", "<cmd>CocCommand explorer<CR>", { silent = true, nowait = true })

vim.api.nvim_create_user_command("Format", ":call CocActionAsync('format')", { desc = "Formats buffer" })
vim.api.nvim_create_user_command("Fold", ":call CocAction('fold', <f-args>)", { desc = "Folds code" })
vim.api.nvim_create_user_command("OR", ":call CocActionAsync('runCommand', 'editor.action.organizeImport')",
    { desc = "Orginizes imports" })

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

