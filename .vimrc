" Simple Voonami .vimrc file
" vim:set ts=2 sts=2 sw=2 expandtab:
packloadall
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" BASIC EDITING STUFF
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set t_Co=256
set nocompatible
" allow unsaved background buffers and remember marks/undo for them
set hidden
" remember more commands and search history
set history=10000
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set laststatus=2
set showmatch
set incsearch
set hlsearch
" Turn on mouse because with integrated clipboard this is nice again.
set mouse=a
" make searches case-sensitive only if they contain upper-case characters
set ignorecase smartcase
" highlight current line
" set cursorline
set cmdheight=1
set switchbuf=useopen
" Add tab name to top of window
set showtabline=2
" Prevent Vim from clobbering the scrollback buffer. See
" http://www.shallowsky.com/linux/noaltscreen.html
" set t_ti= t_te=
set scrolloff=3
" allow backspacing over everything in insert mode
set backspace=indent,eol,start
syntax on
set re=0
" Enable file type detection.
" Use the default filetype settings, so that mail gets 'tw' set to 72,
" 'cindent' is on in C files, etc.
" Also load indent files, to automatically do language-dependent indenting.
filetype plugin indent on
" use emacs-style tab completion when selecting files, etc
set wildmode=longest,list
" make tab completion for files/buffers act like bash
set wildmenu

filetype on
let mapleader=","
let maplocalleader="\\"

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COLOR
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set background=dark
colorscheme minimalist

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" KEY MAPPINGS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" remove search highlight
nnoremap <leader><CR> :nohlsearch<CR>
" delete current line - changed to c-x because c-d is a system mapping.
" nnoremap <c-x> dd
" inoremap <c-x> <esc>ddi
" inoremap <c-X> <esc>cc

" upcase current word in insert mode
inoremap <c-u> <esc>viwUi

" split screen and edit ~/.vimrc
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" split screen and edit ~/.tmux.conf
nnoremap <leader>et :vsplit ~/.tmux.conf<cr>

" double quote current word
nnoremap <leader>" viw<esc>a"<esc>hbi"<esc>lel

" move cursor to beginning of the line in normal mode
nnoremap H ^

" move cursor to end of line in normal mode
nnoremap L $

" Move around splits with <c-hjkl>
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" Change to previous buffer
nnoremap <leader>m <c-^>

" Use system clipboard
set clipboard=unnamed
" if $TMUX == ''
"   set clipboard+=unnamed
" endif

" CTRL+Space does auto complete
inoremap <Nul> <C-n>

" Apply the . command to all selected lines in visual mode
vnoremap <Leader>. :normal.<cr>

" Insert a hash rocket with <c-l>
imap <c-l> <space>=><space>

" Convert and line to a block start
imap <c-d> <end><space>do<cr>

" Open the editor in its own left split
map <leader>e :Vexplore<cr>

" Open rails routes in a split window
map <leader>gr :topleft :split config/routes.rb<cr>
" Open the Gemfile in a split window
map <leader>gg :topleft 100 :split Gemfile<cr>

" Mapping for unobtrusive editing (IE: save without removing whitespace)
map <Leader>w :noautocmd w<cr>

" File types to hide in the file browser
let g:netrw_list_hide= '.*\.swp$'

" Elixir autocmd's
augroup filetype_elixir
	autocmd!
	autocmd FileType elixir setlocal number

  " remove traling whitespace
  autocmd BufWritePre *.ex :%s/\s\+$//e
  autocmd BufWritePre *.exs :%s/\s\+$//e
augroup END

au BufRead,BufNewFile *.ex,*.exs set filetype=elixir
au BufRead,BufNewFile *.eex,*.heex,*.leex,*.sface,*.lexs set filetype=eelixir
au BufRead,BufNewFile mix.lock set filetype=elixir

" Javascript autocmd's
augroup filetype_js
	autocmd!
	autocmd FileType javascript setlocal number
	" Comment line of code
	autocmd FileType javascript nnoremap <buffer> <localleader>c 0i//<esc>
	" autocmd BufWrite,BufRead *.js :normal gg=G
  " remove traling whitespace
  autocmd BufWritePre *.js :%s/\s\+$//e
augroup END

" Ruby autocmd's
augroup filetype_ruby
	autocmd!
	autocmd FileType ruby setlocal number

	" Comment line of code
	autocmd FileType ruby nnoremap <buffer> <localleader>c 0i#<esc>

	" reformat entire file on read/write
  " autocmd BufWrite,BufRead *.rb :normal gg=G

  " remove traling whitespace
  autocmd BufWritePre *.rb :%s/\s\+$//e
augroup END

augroup filetype_html
	autocmd!
	autocmd FileType html setlocal number
	" autocmd BufWrite,BufRead *.html :normal gg=G
	" autocmd BufWrite,BufRead *.haml :normal gg=G
augroup END

augroup filetype_go
  autocmd!
  autocmd FileType go setlocal number
augroup END

autocmd FileType gitcommit setlocal spell textwidth=72

" Expand %% to current dir
cnoremap %% <C-R>=expand('%:h').'/'<cr>

" Statusline
" [RO] full file name modified
set statusline=%R%F\ %m
" right align everything else
set statusline+=%=
" [Column:line:Total Lines]
set statusline+=\[%c\:%l\/%L\]
" Percentage complete
set statusline+=\ \ %P

" " The following is taken from  https://www.destroyallsoftware.com/file-navigation-in-vim.html
" set winwidth=88
" " We have to have a winheight bigger than we want to set winminheight. But if
" " we set winheight to be huge before winminheight, the winminheight set will
" " fail.
" set winheight=5
" set winminheight=5
" set winheight=999

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RENAME CURRENT FILE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RenameFile()
    let old_name = expand('%')
    let new_name = input('New file name: ', expand('%'))
    if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        exec ':silent !rm ' . old_name
        redraw!
    endif
endfunction
map <leader>n :call RenameFile()<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PROMOTE VARIABLE TO RSPEC LET
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! PromoteToLet()
  :normal! dd
  " :exec '?^\s*it\>'
  :normal! P
  :.s/\(\w\+\) = \(.*\)$/let(:\1) { \2 }/
  :normal ==
endfunction
:command! PromoteToLet :call PromoteToLet()
:map <leader>p :PromoteToLet<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" MULTIPURPOSE TAB KEY
" Indent if we're at the beginning of a line. Else, do completion.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction
inoremap <tab> <c-r>=InsertTabWrapper()<cr>
inoremap <s-tab> <c-n>

let g:ackprg = 'ag --nogroup --nocolor --column'

" tslime/rspec
let g:rspec_command = 'call Send_to_Tmux("rspec {spec}\n")'

" vim-rspec mappings
map <leader>r :call RunCurrentSpecFile()<CR>
map <leader>s :call RunNearestSpec()<CR>
map <leader>l :call RunLastSpec()<CR>
map <leader>a :call RunAllSpecs()<CR>

let g:tslime_always_current_session = 1
let g:tslime_always_current_window = 1

let g:ctrlp_cache_dir = $HOME . '/.cache/ctrlp'
" if executable('ag')
"   let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
" endif

let g:ctrlp_custom_ignore = {
  \ 'dir': '\.git$\|\.yardoc\|public$\|node_modules$\|dist\|build$'
  \ }
set number
