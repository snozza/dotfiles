execute pathogen#infect()
if !exists("g:syntax_on")
    syntax enable
endif
filetype plugin indent on

"let g:syntastic_debug = 3

"Vim-Plug
call plug#begin('~/.vim/plugged')

Plug 'sheerun/vim-polyglot'
Plug 'dense-analysis/ale'
Plug 'editorconfig/editorconfig-vim'
Plug 'preservim/nerdtree'
Plug 'github/copilot.vim'
Plug 'lifepillar/vim-solarized8'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

"vim-solarized
set termguicolors
colorscheme solarized8


"syntastic linter
function! SyntasticESlintChecker()
  let l:npm_bin = ''
  let l:eslint = 'eslint'

  if executable('npm')
      let l:npm_bin = split(system('npm bin'), '\n')[0]
  endif

  if strlen(l:npm_bin) && executable(l:npm_bin . '/eslint')
    let l:eslint = l:npm_bin . '/eslint'
  endif

  let g:syntastic_javascript_eslint_exec = l:eslint
endfunction

"Linting
let g:syntastic_javascript_checkers = ["eslint"]
let g:syntastic_go_checkers = ['go', 'golint', 'govet']
let g:syntastic_mode_map = { 'passive_filetypes': ['python'] }
let g:flake8_show_quickfix=0

autocmd BufWritePost *.py call Flake8()

"Copilot
let g:copilot_workspace_folders = ['~/blended']
let g:node_host_prog = '~/.nvm/versions/node/v20.11.1/lib/node_modules'
let g:copilot_node_command = '~/.nvm/versions/node/v20.11.1/bin/node'

"Ale
let g:ale_fixers = {
      \'*': ['remove_trailing_lines', 'trim_whitespace'],
      \'javascript': ['eslint'],
      \'css': ['prettier'],
      \'javascriptreact': ['eslint'],
      \'typescript': ['eslint'],
      \'typescriptreact': ['eslint']
      \}

let g:ale_fix_on_save = 1

autocmd FileType javascript :call SyntasticESlintChecker()

"Airline
let g:airline_theme = 'deus'
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#tabline#enabled = 1

"jsx syntax
let g:jsx_ext_required = 1

"js specific
let g:javascript_plugin_jsdoc = 1

"sql/postgres/ddl
au BufReadPost *.ddl set filetype=sql

set number
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set nocompatible
set modelines=0
set encoding=utf-8
set scrolloff=3
set autoindent
set showmode
set showcmd
set hidden
set wildmenu
set wildmode=list:longest
set visualbell
set ttyfast
set ruler
set backspace=indent,eol,start
set laststatus=2
set noswapfile
set undofile
set backupdir=~/.vim/.backup//
set directory=~/.vim/.swp//
let mapleader = ","
nnoremap / /\v
vnoremap / /\v
nnoremap <CR> :wa<CR>:!!<CR>
set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
nnoremap <leader><space> :noh<cr>
nnoremap <tab> %
vnoremap <tab> %
set wrap
set textwidth=79
set formatoptions=qrn1
set colorcolumn=100
set cursorline
inoremap jj <ESC>
inoremap § <ESC>
nnoremap ; :
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
nnoremap j gj
nnoremap k gk

inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>
nnoremap <leader>w <C-w>v<C-w>1
nnoremap <leader>q <C-w>q
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <leader>W :%s/\s\+$//<cr>:let @/=''<CR>
nnoremap <leader>v V`]
nnoremap <leader>w <C-w>v<C-w>l
imap <C-l> <Plug>(copilot-next)
imap <C-k> <Plug>(copilot-previous)

nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
nnoremap <leader>cp :let @+=expand('%:p')<CR>:echo "Copied: " . @+<CR>
autocmd StdinReadPre * let s:std_in=1
map <C-n> :NERDTreeToggle<CR>
nnoremap <Tab> <C-W><C-W>
set runtimepath^=~/.vim/bundle/ctrlp.vim
set shell=zsh\ -l
