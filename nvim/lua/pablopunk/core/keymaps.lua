vim.g.mapleader = " " -- space

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- ^c is ESC
keymap.set("n", "<c-c>", "<esc>", opts)
keymap.set("v", "<c-c>", "<esc>", opts)
keymap.set("i", "<c-c>", "<esc>", opts)
keymap.set("i", "<c-c>", "<esc>", opts)

-- disable q: and Q because they are so f**king annoying
keymap.set("n", "q:", "<nop>", opts)
keymap.set("n", "Q", "<nop>", opts)

-- remove highlights
keymap.set("n", "<leader>h", ":nohl<cr>", { silent = true })

-- quit/save file
keymap.set("n", "<c-q>", ":bd<cr>", opts)
keymap.set("n", "<c-s>", ":w!<cr>", opts)

-- system clipboard
keymap.set("n", "<leader>cp", '"*y')
keymap.set("v", "<leader>cp", '"*y')

-- Y should not be the same as yy
keymap.set("n", "Y", "y$", opts)

-- buffer navigation
keymap.set("n", "gp", ":bprev<cr>", opts)
keymap.set("n", "gn", ":bnext<cr>", opts)

-- search & replace in current file/line
keymap.set("v", "<c-n>", '"9y:%s@<c-r>9@<c-r>9@g<left><left>')
keymap.set("n", "<c-n>", 'viw"9y:%s@<c-r>9@<c-r>9@g<left><left>')
keymap.set("v", "<leader>n", '"9y:s@<c-r>9@<c-r>9@g<left><left>')
keymap.set("n", "<leader>n", 'viw"9y:s@<c-r>9@<c-r>9@g<left><left>')

-- follow (center) search cursor
keymap.set("n", "n", "nzz", opts)
keymap.set("n", "N", "Nzz", opts)
keymap.set("n", "*", "*zz", opts)

-- + will highlight all matches
keymap.set("n", "+", "*N", opts)

-- easier block indentation
keymap.set("n", ">", ">>", opts)
keymap.set("n", "<", "<<", opts)
keymap.set("v", ">", ">gv", opts)
keymap.set("v", "<", "<gv", opts)

-- folding
keymap.set("n", "<leader><", "zM", opts) -- fold all
keymap.set("n", "<leader>>", "zR", opts) -- open all
-- keymap.set("n", "H", "za", opts) -- toggle fold under cursor (depends on fold_method)
keymap.set("n", "H", "zc", opts) -- close fold under cursor
keymap.set("n", "L", "zo", opts) -- open fold under cursor
