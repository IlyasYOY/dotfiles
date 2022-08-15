syntax on 
filetype plugin on
set nocompatible

set exrc 
set nu
set relativenumber 
set nohlsearch
set hidden 
set noerrorbells 
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab 
set smartindent 
set noswapfile 
set nobackup
set undodir=~/.vim/undodir
set undofile 
set incsearch
set scrolloff=8
set signcolumn=yes 
set colorcolumn=80
set showcmd
set belloff=all
set cursorline

" File explorer settings
let g:netrw_banner = 0 " Now we won't have bloated top of the window 
let g:netrw_liststyle = 3 " Now it will be a tree view  

nnoremap <C-w>t :tabnew<CR>
nnoremap <SPACE> <Nop>

nnoremap <F3> :w<cr>
" This allows me to save from inssert mode 
inoremap <F3> <C-\><C-o>:w<CR>

let mapleader = "\<Space>" 

" map <leader>s :Sex!<CR>

imap jj <Esc>

" Russian mapppings
map й q
map ц w
map у e
map к r
map е t
map н y
map г u
map ш i
map щ o
map з p
map х [
map ъ ]
map ф a
map ы s
map в d
map а f
map п g
map р h
map о j
map л k
map д l
map ж ;
map э '
map ё \
map я z
map ч x
map с c
map м v
map и b
map т n
map ь m
map б ,
map ю .
map Й Q
map Ц W
map У E
map К R
map Е T
map Н Y
map Г U
map Ш I
map Щ O
map З P
map Х {
map Ъ }
map Ф A
map Ы S
map В D
map А F
map П G
map Р H
map О J
map Л K
map Д L
map Ж :
map Э "
map Я Z
map Ч X
map С C
map М V
map И B
map Т N
map Ь M
map Б <
map Ю >
map Ё /|


