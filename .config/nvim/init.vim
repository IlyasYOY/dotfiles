" Basic setup 
source ~/.vimrc

" Plugins
call plug#begin('~/.vim/plugged')

" coc configuration 
" coc-go
" coc-pyright
" coc-rust-analyzer
" coc-json
" coc-java 
" coc-vimlsp
" coc-lua
" coc-lists
" coc-markdownlint
" coc-snippets
Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'tpope/vim-fugitive'

Plug 'vim-airline/vim-airline'
Plug 'airblade/vim-gitgutter'

" This allows me to do fuzzy search 
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'honza/vim-snippets'

" Themes
Plug 'gruvbox-community/gruvbox'
Plug 'tanvirtin/monokai.nvim'
Plug 'tomasiser/vim-code-dark'

" Some utilities for lua IO
Plug 'nvim-lua/plenary.nvim'

call plug#end()

" Colors 
" colorscheme gruvbox
" colorscheme monokai
" colorscheme monokai_pro
" colorscheme monokai_soda
" colorscheme monokai_ristretto
colorscheme codedark

" Fzf
" Trigger fuzzy files search prvided by fzf
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fc :Ag<CR>
let g:fzf_buffers_jump = 1

" Terminal mappings
" Use <Esc> to close the terminal
tnoremap <Esc> <C-\><C-n>

"" CoC
" More here: https://github.com/neoclide/coc.nvim#example-vim-configuration
" Interactive mode mappings 
inoremap <silent><expr> <S-space> coc#refresh()
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gD <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nnoremap <silent> <leader>q :call ShowDocumentation()<CR>
inoremap <C-P> <C-\><C-O>:call CocActionAsync('showSignatureHelp')<cr>

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>l  <Plug>(coc-format-selected)
nmap <leader>l  <Plug>(coc-format-selected)
nmap <leader>L :Format<CR>
nmap <leader>O :OR<CR>

" Apply AutoFix to problem on the current line.
nmap <leader><cr>  <Plug>(coc-fix-current)

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Find symbol of current document.
nnoremap <silent><nowait> <leader>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <leader>s  :<C-u>CocList -I symbols<cr>
" Show me the lists
nnoremap <silent><nowait> <leader>cl  :<C-u>CocList<cr>

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
