-- highlight yanked text
vim.cmd [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup end
]]

-- templates
vim.cmd [[
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
]]
