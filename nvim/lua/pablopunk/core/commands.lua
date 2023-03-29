-- I disabled netrw so I need Browse to use GBrowse
vim.cmd [[ command! -nargs=1 Browse silent execute '!open' shellescape(<q-args>,1) ]]
