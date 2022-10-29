vim.g.mapleader = " " -- space

local keymap = vim.keymap

-- ^c is ESC
keymap.set("n", "<c-c>", "<esc>")
keymap.set("v", "<c-c>", "<esc>")
keymap.set("i", "<c-c>", "<esc>")
keymap.set("i", "<c-c>", "<esc>")

-- c-hjlk to move through windows
-- keymap.set("n", "<c-h>", "<c-w>h")
-- keymap.set("n", "<c-j>", "<c-w>j")
-- keymap.set("n", "<c-k>", "<c-w>k")
-- keymap.set("n", "<c-l>", "<c-w>l")

-- remove highlights
keymap.set("n", "<leader>h", ":nohl<cr>")
keymap.set("n", "<leader>h", ":nohl<cr>")

-- quit/save file
keymap.set("n", "<c-q>", ":bd<cr>")
keymap.set("n", "<c-s>", ":w!<cr>")

-- nvim-tree
keymap.set("n", "<c-t>", ":NvimTreeFindFile<cr>")

-- telescope
keymap.set("n", "<c-p>", "<cmd>Telescope find_files<cr>")
keymap.set("n", "<c-f>", "<cmd>Telescope live_grep<cr>")
keymap.set("n", "<leader>f", "<cmd>Telescope grep_string<cr>")
keymap.set("n", "<leader><leader>", "<cmd>Telescope buffers<cr>")

-- system clipboard
keymap.set("n", "<leader>cp", '"*y')
keymap.set("v", "<leader>cp", '"*y')

-- Y should not be the same as yy
keymap.set("n", "Y", "y$")

-- buffer navigation
keymap.set("n", "gb", ":bprev<cr>")
keymap.set("n", "gn", ":bnext<cr>")

-- search & replace in current file/line
keymap.set("v", "<c-n>", '"9y:%s/<c-r>9/<c-r>9/g<left><left>')
keymap.set("n", "<c-n>", 'viw"9y:%s/<c-r>9/<c-r>9/g<left><left>')
keymap.set("v", "<leader>n", '"9y:s/<c-r>9/<c-r>9/g<left><left>')
keymap.set("n", "<leader>n", 'viw"9y:s/<c-r>9/<c-r>9/g<left><left>')

-- follow (center) search cursor
keymap.set("n", "n", "nzz")
keymap.set("n", "N", "Nzz")
keymap.set("n", "*", "*zz")

-- + will highlight all matches
keymap.set("n", "+", "*N")

-- easier block indentation
keymap.set("n", ">", ">>")
keymap.set("n", "<", "<<")
keymap.set("v", ">", ">gv")
keymap.set("v", "<", "<gv")
