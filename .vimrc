syntax on 
filetype plugin on
set nocompatible

set list listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<

let mapleader = " "
let mapleaderlocal = " "

autocmd VimEnter * :clearjumps

" Allow me to use custom vimrc from the current folder
set exrc 

" Numbers settings
set nu
set relativenumber 

" Bells 
set noerrorbells 
set belloff=all

set termguicolors
set hidden 

" Tabs and indent settings
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab 

if !has('nvim')
    set smartindent 
endif

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
set foldcolumn=1 

" Line length column 
set colorcolumn=80

" heps me to find a current line
set cursorline

" autocomplete for command mode 
set wildmenu
set wildmode=full

" increase history size 
set history=300

" noh - no highlight
nnoremap <Esc> :noh <CR>

nnoremap <F3> :w<CR>
" This allows me to save from inssert mode 
inoremap <F3> <C-\><C-o>:w<CR>

set nowrap

" Switch buffers using keys
nnoremap <silent> [b :bprevious<cr>
nnoremap <silent> ]b :bnext<cr> 
nnoremap <silent> [B :bfirst<cr> 
nnoremap <silent> ]B :blast<cr>

nnoremap <silent> [q :cprevious<cr>
nnoremap <silent> ]q :cnext<cr> 
nnoremap <silent> [Q :cfirst<cr> 
nnoremap <silent> ]Q :clast<cr>
nnoremap <silent> ]u :cnewer<cr>
nnoremap <silent> [u :colder<cr>

nnoremap <silent> [l :lprevious<cr>
nnoremap <silent> ]l :lnext<cr> 
nnoremap <silent> [L :lfirst<cr> 
nnoremap <silent> ]L :llast<cr>

nnoremap <silent> <leader>co :copen<cr>
nnoremap <silent> <leader>cc :cclose<cr>

" :h matchit  
" Helps you to match syntax constuctions in Vim
runtime macros/matchit.vim

set langmap=йq,цw,уe,кr,еt,нy,гu,шi,щo,зp,х[,ъ],фa,ыs,вd,аf,пg,рh,оj,лk,дl,ж\\;,э',ё\\,яz,чx,сc,мv,иb,тn,ьm,б\\,,ю.,ЙQ,ЦW,УE,КR,ЕT,НY,ГU,ШI,ЩO,ЗP,Х{,Ъ},ФA,ЫS,ВD,АF,ПG,РH,ОJ,ЛK,ДL,Ж:,Э\\",ЯZ,ЧX,СC,МV,ИB,ТN,ЬM,Б<,Ю>,Ё/|

imap <C-ц> <C-w>
imap <C-х> <C-[>
imap <C-щ> <C-o>
