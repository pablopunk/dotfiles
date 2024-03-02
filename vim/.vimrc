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
nmap <c-g> :b#<cr>
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
" Comments
function! ToggleCommentRange(startline, endline)
  let l:commentString = (&filetype == 'lua' ? '--' : (&filetype == 'sh' ? '#' : (&filetype == 'vim' ? '"' : '//')))
  let l:allCommented = 1
  for l:line in range(a:startline, a:endline)
      if getline(l:line) !~ '^\s*' . l:commentString . '\s*'
          let l:allCommented = 0
          break
      endif
  endfor
  for l:line in range(a:startline, a:endline)
      execute l:line . (l:allCommented ? 's/^\s*' . l:commentString . '\s*//' : 's/^/' . l:commentString . ' /')
  endfor
endfunction

nnoremap gcc :call ToggleCommentRange(line('.'), line('.'))<CR>
vnoremap gc :<C-u>call ToggleCommentRange(line("'<"), line("'>"))<CR>
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

" Project search (strings) {{{
set grepprg=rg\ --vimgrep\ --follow\ --max-columns=1000\ --case-sensitive
set grepformat=%f:%l:%c:%m,%f:%l:%m
function! Grep(...)
  return system(join([&grepprg] + a:000), ' ')
endfunction
command! -nargs=+ -complete=file_in_path -bar Grep      cgetexpr Grep(<f-args>)
command! -nargs=+ -complete=file_in_path -bar GrepWord  cgetexpr Grep(<f-args> . ' -w')
augroup quickfix
  autocmd!
  autocmd QuickFixCmdPost cgetexpr cwindow
augroup END
nmap <leader>fs :Grep<space><space>.<left><left>
nmap <leader>fw :GrepWord<space><c-r><c-w><space>.<cr>
vmap <leader>fw "9y:Grep<space>'<c-r>9'<space>.<cr>
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
" }}}
