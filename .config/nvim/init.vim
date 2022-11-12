" Basic setup 
source ~/.vimrc

" Terminal mappings
" Use <Esc> to close the terminal
tnoremap <Esc> <C-\><C-n>

" Telescope 
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>

"" CoC
" More here: https://github.com/neoclide/coc.nvim#example-vim-configuration
" Interactive mode mappings 
inoremap <silent><expr> <C-space> coc#refresh()
" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" GoTo code navigation.
" Go Def
nmap <silent> gd <Plug>(coc-definition)
" Go (type) DEF
nmap <silent> gD <Plug>(coc-type-definition)
" Go Impl 
nmap <silent> gi <Plug>(coc-implementation)
" Go Ref
nmap <silent> gr <Plug>(coc-references)

" Help
nnoremap <silent> <leader>h :call ShowDocumentation()<CR>
inoremap <C-s> <C-O>:call CocActionAsync('showSignatureHelp')<cr>

inoremap <silent><expr> <C-p> coc#pum#visible() ? coc#pum#prev(1) : "\<C-p>"

" ReName.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
" Org Code 
xmap <leader>oc  <Plug>(coc-format-selected)
nmap <leader>oc  <Plug>(coc-format-selected)
nmap <leader>oc :Format<CR>
" Org Import 
nmap <leader>oi :OR<CR>
" Org All 
nmap <leader>oa :OR<CR>:Format<CR>

" Apply AutoFix to problem on the current line.
" Help
nmap <leader>H  <Plug>(coc-fix-current)

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
" Action
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Find symbol of current document.
nnoremap <silent><nowait> <leader>O  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <leader>S  :<C-u>CocList -I symbols<cr>
" Show me the lists
nnoremap <silent><nowait> <leader>L  :<C-u>CocList<cr>

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Commands
" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')
" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)
" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')


" Functions
function! ShowDocumentation()
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  elseif CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

"" END CoC

" Telekasten

nnoremap <leader>z :Telekasten<CR>

nnoremap <leader>zb :Telekasten show_backlinks<CR>
nnoremap <leader>zt :Telekasten show_tags<CR>
nnoremap <leader>zz :Telekasten follow_link<CR>
nnoremap <leader>zl :Telekasten insert_link<CR>
nnoremap <leader>zn :Telekasten new_note<CR>

nnoremap <leader>zd :Telekasten goto_today<CR>
nnoremap <leader>zw :Telekasten goto_thisweek<CR>
nnoremap <leader>zc :Telekasten show_calendar<CR>

nnoremap <leader>zrn :Telekasten rename_note<CR>

nnoremap <leader>zff :Telekasten find_notes<CR>
nnoremap <leader>zfg :Telekasten search_notes<CR>

lua << END
local home = vim.fn.expand("~/vimwiki")
require('telekasten').setup({
    home = home,
    take_over_my_home = true,
    auto_set_filetype = true,
    dailies      = home .. '/' .. 'diary',
    weeklies     = home .. '/' .. 'diary',
    templates    = home .. '/' .. 'meta/templates',
    image_subdir = nil,
    extension    = ".md",
    new_note_filename = "uuid-title",
    uuid_type = "%Y-%m-%d %H%M%S",
    uuid_sep = "-",
    follow_creates_nonexisting = true,
    dailies_create_nonexisting = true,
    weeklies_create_nonexisting = true,
    journal_auto_open = false,
    template_new_note = home .. '/' .. 'meta/templates/zettel template.md',
    template_new_daily = home .. '/' .. 'meta/templates/daily template.md',
    template_new_weekly= home .. '/' .. 'meta/templates/weekly template.md',
    image_link_style = "wiki",
    sort = "filename",
    plug_into_calendar = true,
    calendar_opts = {
        weeknm = 1,
        calendar_monday = 1,
        calendar_mark = 'left-fit',
    },
    close_after_yanking = false,
    insert_after_inserting = true,
    tag_notation = "#tag",
    command_palette_theme = "ivy",
    show_tags_theme = "ivy",
    subdirs_in_links = false,
    template_handling = "prefer_new_note",
    new_note_location = "prefer_home",
    rename_update_links = true,
    media_previewer = "telescope-media-files",
})
END
