"
" Plugins
"

" TODO: one day make some of these lazy load
if &loadplugins
    if has('packages')
        packadd! tcomment_vim
        packadd! goyo.vim
        packadd! nerdtree
        packadd! nerdtree-git-plugin
        packadd! vim-devicons
    endif
endif

"
" Tabs and spaces
"

" Tabs are 4 spaces
set tabstop=4

" Auto indent
set autoindent

" Replace tab with white space
set expandtab

" Delete 4 spaces for tab
set softtabstop=4

"
" Cursor
"

" Highlight current line
set cursorline


" Redraw only when needed
set lazyredraw

"
" Search
"

" Search as chars are entered
set incsearch

" Highlight results
set hlsearch

" Unhighligh results with \+<space>
nnoremap <leader><space> :nohlsearch<CR>

"
" History
"

" Number of lines to remember
set history=200

"
" Alerts
"

set noerrorbells
set novisualbell

"
" Enable Syntax
"
syntax enable

"
" Functions
"

