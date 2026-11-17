"
" Plugins
"

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

" Indent with 4 spaces
set tabstop=4
set shiftwidth=4

" Auto indent
set autoindent

" Replace tab with white space
set expandtab

" Delete 4 spaces for tab
set softtabstop=4

"
" Text spacing
"

" Wrap at 75 columns as you type, but only in prose, not code
set textwidth=75
set formatoptions-=t
augroup prose_wrap
    autocmd!
    autocmd FileType markdown,text,gitcommit setlocal formatoptions+=t
augroup END

"
" Cursor
"

" Redraw only when needed
set lazyredraw

"
" Mouse
"
set mouse=a

"
" Search
"

" Search as chars are entered
set incsearch

" Highlight results
set hlsearch

" Unhighlight results with \+<space>
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

