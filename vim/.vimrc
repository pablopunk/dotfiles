" vim:fileencoding=utf-8:ft=vim:foldmethod=marker

" General settings {{{
filetype plugin on
syntax on
set nocompatible ttyfast lazyredraw incsearch hlsearch infercase encoding=utf-8 mouse=a hidden autoread number tabstop=2 shiftwidth=2 softtabstop=2 expandtab smarttab autoindent shiftround wrap ignorecase smartcase cursorline termguicolors backspace=indent,eol,start splitright splitbelow iskeyword+=-
set re=0 " fix error: 'redrawtime' exceeded, syntax highlighting disabled
try
  set signcolumn=number " Show line numbers and signs on the same column"
catch
  set signcolumn=yes    " Fallback for older versions
endtry
" }}}

" Key mapping {{{
" Remap leader key
let mapleader = "\<space>"
" Disable Ex Mode
nmap Q <Nop>
" Ctrl+c is ESC (it is by default but it won't trigger autocommands)
imap <c-c> <esc>
" Ctrl+hjkl moves split focus
nmap <c-h> <c-w>h
nmap <c-j> <c-w>j
nmap <c-k> <c-w>k
nmap <c-l> <c-w>l
" Use + to select all word matches
nmap + *N
" Center match when navigating through search results
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
" Use <c-g> to change ocurrences of a word/selection one by one (similar to Sublime Text and VSCode)
nnoremap <c-g> *`'cgn
vnoremap <c-g> y<cmd>let @/=escape(@", '/')<cr>"_cgn
" Ctrl+q close buffer
nmap <c-q> :bd<cr>
" Ctrl+s to save
nmap <c-s> :w<cr>
" Use system clipboard (reg *)
nmap <leader>y "*y
vmap <leader>y "*y
nmap <leader>p "*p
vmap <leader>p "*p
" Y should not be the same as yy
nmap Y y$
" Navigate buffers
nmap <c-p> :bprev<cr>
nmap <c-n> :bnext<cr>
nmap <c-f> :ls<CR>:b<Space>
" Navigate quickfix window
nmap <leader>]q :cnext<cr>
nmap <leader>[q :cprev<cr>
" Disable arrow keys
nmap <Up> <Nop>
nmap <Down> <Nop>
nmap <Left> <Nop>
nmap <Right> <Nop>
" Easier block indentation
nnoremap > >>
nnoremap < <<
vnoremap > >gv
vnoremap < <gv
" I use () to navigate instead of []
nmap ( [
nmap ) ]
omap ( [
omap ) ]
xmap ( [
xmap ) ]
" Search and replace
vnoremap <leader>rw "9y:%s/<c-r>9/<c-r>9/g<left><left>
nnoremap <leader>rw viw"9y:%s/<c-r>9/<c-r>9/g<left><left>
vnoremap <leader>rl "9y:s/<c-r>9/<c-r>9/g<left><left>
nnoremap <leader>rl viw"9y:s/<c-r>9/<c-r>9/g<left><left>
" Map ESC key to exit insert mode in :terminal (vim8 or neovim)
if has('terminal') || has('nvim')
  tmap <Esc> <C-\><C-n>
endif
" Remove highlights
nmap <silent> <leader>h :noh<cr>
function! FoldAll()
  set foldmethod=indent
  normal! zM
endfunction
function! UnfoldAll()
  set nofoldenable
  normal! zR
endfunction
nnoremap <leader>< :call FoldAll()<cr>
nnoremap <silent> <leader>> :call UnfoldAll()<cr>
" }}}

" Autocommands {{{
" I don't wanna save changes to a directory ¬¬
autocmd FileType netrw setl bufhidden=delete
augroup templates
  autocmd!
  autocmd BufNewFile *.tsx,*.jsx
    \ 0r $HOME/.config/nvim/templates/react.tsx |
    \ %s/FILENAME/\=expand('%:t:r')/g
  autocmd BufNewFile *_document.*
    \ 0r $HOME/.config/nvim/templates/_document.tsx
  autocmd BufNewFile *.json
    \ 0r $HOME/.config/nvim/templates/empty.json |
    \ exe "normal ggo"
augroup end
" }}}

" Abbreviations {{{
iabbr widht width
iabbr heigth height
iabbr lenght length
iabbr ligth light
iabbr rigth right
iabbr ireact import React from 'react'
iabbr fcreact const Component = () =>
iabbr ccreact class Component extends React.Component
" }}}

" File finder {{{
runtime! plugin/**/*.vim " load plugins even if -u NONE (e.g netrw)
set path+=** " Search files subdirectories
set wildmenu " Allow autocomplete on 'find' command
set wildignore+=**/node_modules/**
set wildignore+=**/dist/**

function! FindFiles(filename)
  let l:error_file = tempname()
  silent exe '!fd -H -t f '.a:filename.' | xargs file | sed "s/:/:1:/" > '.l:error_file
  set errorformat=%f:%l:%m
  execute "cfile ".l:error_file
  copen
  if line('$') == 1 | wincmd w | endif
  call delete(l:error_file)
endfunction

function! GitModifiedFiles()
  call setqflist(map(split(system("git ls-files -m"), "\n"), '{"filename": v:val, "lnum": 1, "col": 1, "text": "modified"}'))
  copen
endfunction

command! -nargs=1 Find call FindFiles(<q-args>)
nmap <leader>ff :Find<space>
command! GitModifiedFiles call GitModifiedFiles()
nmap <leader>fg :GitModifiedFiles<cr>
" }}}

" Telescope {{{
if empty(glob('~/.local/share/nvim/site/pack/packer/start/telescope.nvim'))
  silent !mkdir -p ~/.local/share/nvim/site/pack/packer/start
  silent !git clone --depth 1 https://github.com/nvim-telescope/telescope.nvim ~/.local/share/nvim/site/pack/packer/start/telescope.nvim
endif
if empty(glob('~/.local/share/nvim/site/pack/packer/start/plenary.nvim'))
  silent !mkdir -p ~/.local/share/nvim/site/pack/packer/start
  silent !git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/packer/start/plenary.nvim
endif
packadd plenary.nvim
packadd telescope.nvim
lua << EOF
  require('telescope').setup{
    file_ignore_patterns = { ".git/", "node_modules/", "vendor/" },
    path_display = { "truncate" }, -- if it doesn't fit, show the end (.../foo/bar.js)
    layout_strategy = "vertical",
    layout_config = {
      vertical = {
        preview_cutoff = 0,
      },
    },
    selection_caret = "◦ ",
    prompt_prefix = " → ",
    mappings = {
      i = {
        ["<c-k>"] = require("telescope.actions").cycle_history_prev,
        ["<c-j>"] = require("telescope.actions").cycle_history_next,
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
      grep_string = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
      live_grep = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
    },
  }
EOF
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fs <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <c-f> <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').git_files()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
nnoremap <leader>fw <cmd>lua require('telescope.builtin').grep_string()<cr>
nnoremap <leader>fW <cmd>lua require('telescope.builtin').grep_string({ hidden = true })<cr>
nnoremap <leader>fr <cmd>lua require('telescope.builtin').oldfiles()<cr>
" }}}

" Copilot {{{
if empty(glob('~/.local/share/nvim/site/pack/packer/start/supermaven-nvim'))
  silent !mkdir -p ~/.local/share/nvim/site/pack/packer/start
  silent !git clone --depth 1 https://github.com/supermaven-inc/supermaven-nvim ~/.local/share/nvim/site/pack/packer/start/supermaven-nvim
endif
if empty(glob('~/.local/share/nvim/site/pack/packer/start/copilot.lua'))
  silent !mkdir -p ~/.local/share/nvim/site/pack/packer/start
  silent !git clone --depth 1 https://github.com/zbirenbaum/copilot.lua ~/.local/share/nvim/site/pack/packer/start/copilot.lua
endif
packadd supermaven-nvim
lua << EOF
  require('supermaven-nvim').setup {}
EOF
" }}}

" File tree {{{
let g:file_tree_shortcut = '<c-t>'
exe 'nnoremap <silent> ' g:file_tree_shortcut ' :Lexplore %:p:h<cr>'
exe 'vnoremap <silent> ' g:file_tree_shortcut ' :Lexplore %:p:h<cr>'
exe 'inoremap <silent> ' g:file_tree_shortcut ' <esc>:Lexplore %:p:h<cr>'

augroup netrw_mapping
  autocmd!
  autocmd filetype netrw call NetrwMapping()
augroup END

function! NetrwMapping()
  nmap <buffer> <c-l> <c-w>l
endfunction

let g:netrw_altv=1
let g:netrw_banner=0
let g:netrw_winsize=20
let g:netrw_liststyle=0
let g:netrw_browse_split=0
let g:netrw_list_hide='.*\.git/$,'.netrw_gitignore#Hide()
" }}}

" mini.nvim {{{
if empty(glob('~/.local/share/nvim/site/pack/packer/start/mini.nvim'))
  silent !mkdir -p ~/.local/share/nvim/site/pack/packer/start
  silent !git clone --depth 1 https://github.com/echasnovski/mini.nvim ~/.local/share/nvim/site/pack/packer/start/mini.nvim
endif
packadd mini.nvim
lua << EOF
  require("mini.completion").setup {}
  require("mini.comment").setup {}
  require("mini.indentscope").setup { symbol = "│" }
  require("mini.diff").setup {}

EOF
" }}}

" Color config {{{
set background=dark
colorscheme habamax
" Groups to be transparent
let g:higroups = [
  \ 'Normal',
  \ 'NormalSB',
  \ 'NormalNC',
  \ 'LineNr',
  \ 'SignColumn',
  \ 'NonText',
  \ 'EndOfBuffer',
  \ ]
for g:color in g:higroups
  execute 'silent! hi ' . g:color . ' guibg=NONE'
endfor
