-- vim:fileencoding=utf-8:ft=lua:foldmethod=marker

vim.g.mapleader = " " -- space

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- ^c is ESC {{{
opts.desc = "ESC"
keymap.set("n", "<c-c>", "<esc>", opts)
keymap.set("v", "<c-c>", "<esc>", opts)
keymap.set("i", "<c-c>", "<esc>", opts)
keymap.set("i", "<c-c>", "<esc>", opts)
-- }}}

-- Disable q: and Q because they are so f**king annoying {{{
opts.desc = "Noop"
keymap.set("n", "q:", "<nop>", opts)
keymap.set("n", "Q", "<nop>", opts)
-- }}}

-- Remove highlights {{{
opts.desc = "Remove highlights"
keymap.set("n", "<leader>h", ":nohl<cr>", { silent = true })
-- }}}

-- Quit/Save file {{{
opts.desc = "Close buffer"
keymap.set("n", "<c-q>", ":bd<cr>", opts)
opts.desc = "Save file"
keymap.set("n", "<c-s>", ":w!<cr>", opts)
-- }}}

-- System clipboard {{{
opts.desc = "Copy to system clipboard"
keymap.set("n", "<leader>cp", '"*y')
keymap.set("v", "<leader>cp", '"*y')
-- }}}

-- Y should not be the same as yy {{{
opts.desc = "Yank til end of line"
keymap.set("n", "Y", "y$", opts)
-- }}}

-- Buffer navigation {{{
opts.desc = "Previous buffer"
keymap.set("n", "gp", ":bprev<cr>", opts)
opts.desc = "Next buffer"
keymap.set("n", "gn", ":bnext<cr>", opts)
-- }}}

-- Search & replace in current file/line {{{
opts.desc = "Search & replace selection in current file"
keymap.set("v", "<c-n>", '"9y:%s@<c-r>9@<c-r>9@g<left><left>')
opts.desc = "Search & replace current word in current file"
keymap.set("n", "<c-n>", 'viw"9y:%s@<c-r>9@<c-r>9@g<left><left>')
opts.desc = "Search & replace selection in current line"
keymap.set("v", "<leader>n", '"9y:s@<c-r>9@<c-r>9@g<left><left>')
opts.desc = "Search & replace current word in current line"
keymap.set("n", "<leader>n", 'viw"9y:s@<c-r>9@<c-r>9@g<left><left>')
-- }}}

-- Follow cursor while searching {{{
opts.desc = "Next match and center"
keymap.set("n", "n", "nzz", opts)
opts.desc = "Previous match and center"
keymap.set("n", "N", "Nzz", opts)
opts.desc = "All matches and center"
keymap.set("n", "*", "*zz", opts)
-- }}}

-- Highlight matches with + {{{
opts.desc = "Highlight all matches"
keymap.set("n", "+", "*N", opts)
-- }}}

-- Block indentation (easier) {{{
opts.desc = "Indent right"
keymap.set("n", ">", ">>", opts)
opts.desc = "Indent left"
keymap.set("n", "<", "<<", opts)
opts.desc = "Indent selection right"
keymap.set("v", ">", ">gv", opts)
opts.desc = "Indent selection left"
keymap.set("v", "<", "<gv", opts)
-- }}}

-- Folds {{{
opts.desc = "Fold all"
keymap.set("n", "<leader><", "zM", opts) -- fold all
opts.desc = "Open all folds"
keymap.set("n", "<leader>>", "zR", opts) -- open all
-- keymap.set("n", "H", "za", opts) -- toggle fold under cursor (depends on fold_method)
opts.desc = "Close fold under cursor"
keymap.set("n", "H", "zc", opts) -- close fold under cursor
opts.desc = "Open fold under cursor"
keymap.set("n", "L", "zo", opts) -- open fold under cursor
-- }}}
