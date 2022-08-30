" Basic setup 
source ~/.vimrc

" Terminal mappings
" Use <Esc> to close the terminal
tnoremap <Esc> <C-\><C-n>

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
inoremap <C-s> <C-\><C-O>:call CocActionAsync('showSignatureHelp')<cr>

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
