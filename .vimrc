syntax on 
filetype plugin on
set nocompatible

" Allow me to use custom vimrc from the current folder
set exrc 

" Numbers settings
set nu
set relativenumber 

" Bells 
set noerrorbells 
set belloff=all

set hidden 

" Tabs and indent settings
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab 
set smartindent 

" Swap files 
set noswapfile 
set nobackup

" Undo files 
set undodir=~/.vim/undodir
set undofile 

" Shows the search before we 
set incsearch

" Number of lines to keep above/below the cursor 
set scrolloff=8

" Column with extra info 
set signcolumn=yes 

" Line length column 
set colorcolumn=80

" Shows currently running command
set showcmd

" heps me to find a current line
set cursorline

" autocomplete for command mode 
set wildmenu
set wildmode=full

" increase history size 
set history=50

" File explorer settings
let g:netrw_banner = 0 " Now we won't have bloated top of the window 
let g:netrw_liststyle = 3 " Now it will be a tree view  

nnoremap <C-w>t :tabnew<CR>
nnoremap <SPACE> <Nop>

" noh - no highlight
nnoremap <Esc> :noh <CR>

nnoremap <F3> :w<CR>
" This allows me to save from inssert mode 
inoremap <F3> <C-\><C-o>:w<CR>

let mapleader = "\<Space>" 

" map <leader>s :Sex!<CR>

" Switch buffers using keys
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR> 
nnoremap <silent> [B :bfirst<CR> 
nnoremap <silent> ]B :blast<CR>

imap jj <Esc>

" Set keymap so i can run commands in russian 
" This option doesn't work very well 
" https://habr.com/en/post/175709/
" https://github.com/vim/vim/blob/master/runtime/keymap/russian-jcukenmac.vim
" set keymap=russian-jcukenmac

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


