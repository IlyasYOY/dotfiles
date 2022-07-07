source ~/.vimrc

call plug#begin('~/.vim/plugged')
" Use release branch (recommend)
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'gruvbox-community/gruvbox'
call plug#end()

colorscheme gruvbox

map <C-p> :Files<CR>

tnoremap <Esc> <C-\><C-n>

