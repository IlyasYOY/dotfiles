local mapping = require("map-functions")

local map_normal = mapping.map_normal
local map_interactive = mapping.map_interactive
local map_visual = mapping.map_visual
local map_operator = mapping.map_operator

-- CoC commands

-- More here: https://github.com/neoclide/coc.nvim#example-vim-configuration
-- Interactive mode mappings
map_interactive("<C-space>", "coc#refresh()", { silent = true, expr = true })
-- Make <CR> to accept selected completion item or notify coc.nvim to format
-- <C-g>u breaks current undo, please make your own choice.
map_interactive("<CR>", "coc#pum#visible() ? coc#pum#confirm() : \"\\<C-g>u\\<CR>\\<c-r>=coc#on_enter()\\<CR>\"",
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

map_interactive("<C-s>", "<C-O>:call CocActionAsync('showSignatureHelp')<CR>")
map_interactive("<C-p>", "coc#pum#visible() ? coc#pum#prev(1) : \"\\<C-p>\"", { silent = true, expr = true })

-- ReName.
map_normal("<leader>rn", "<Plug>(coc-rename)")

-- Formatting selected code.
-- Org Code
map_visual("<leader>oc", " <Plug>(coc-format-selected)")
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
map_normal("<leader>a ", "<Plug>(coc-codeaction-selected)", { silent = true, nowait = true })
map_visual("<leader>a", "<Plug>(coc-codeaction-selected)", { silent = true, nowait = true })

-- Use CTRL-S for selections ranges.
-- Requires 'textDocument/selectionRange' support of language server.
map_normal("<C-s>", "<Plug>(coc-range-select)", { silent = true })
map_visual("<C-s>", "<Plug>(coc-range-select)", { silent = true })

-- Map function and class text objects
-- NOTE: Requires 'textDocument.documentSymbol' support from the language server.
map_visual("if", "<Plug>(coc-funcobj-i)", { silent = true, nowait = true })
map_operator("if", "<Plug>(coc-funcobj-i)", { silent = true, nowait = true })
map_visual("af", "<Plug>(coc-funcobj-a)", { silent = true, nowait = true })
map_operator("af", "<Plug>(coc-funcobj-a)", { silent = true, nowait = true })
map_visual("ic", "<Plug>(coc-classobj-i)", { silent = true, nowait = true })
map_operator("ic", "<Plug>(coc-classobj-i)", { silent = true, nowait = true })
map_visual("ac", "<Plug>(coc-classobj-a)", { silent = true, nowait = true })
map_operator("ac", "<Plug>(coc-classobj-a)", { silent = true, nowait = true })

-- Find symbol of current document.
map_normal("<leader>O", "<cmd>CocList outline<CR>", { silent = true, nowait = true })
-- Search workspace symbols.
map_normal("<leader>S", "<cmd>CocList -I symbols<CR>", { silent = true, nowait = true })
-- Show me the lists
map_normal("<leader>L", "<cmd>CocList<CR>", { silent = true, nowait = true })
-- Show me the lists
map_normal("<leader>E", "<cmd>CocCommand explorer<CR>", { silent = true, nowait = true })



vim.api.nvim_create_user_command("CocInstallMyExtensions",
    ":CocInstall coc-go coc-java coc-json coc-lists coc-pyright coc-rust-analyzer coc-snippets coc-vimlsp coc-explorer coc-sumneko-lua"
    , { desc = "Installs all my extensions" })
vim.api.nvim_create_user_command("Format", ":call CocActionAsync('format')", { desc = "Formats buffer" })
vim.api.nvim_create_user_command("Fold", ":call CocAction('fold', <f-args>)", { desc = "Folds code" })
vim.api.nvim_create_user_command("OR", ":call CocActionAsync('runCommand', 'editor.action.organizeImport')",
    { desc = "Orginizes imports" })
