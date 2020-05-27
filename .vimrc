" Load pathogen 
execute pathogen#infect()

" Enable syntax 
syntax enable

" Enable solarized theme
set background=dark
colorscheme solarized

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

