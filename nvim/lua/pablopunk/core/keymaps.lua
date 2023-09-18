-- vim:fileencoding=utf-8:ft=lua:foldmethod=marker

vim.g.mapleader = " " -- space

local keymap = vim.keymap
local function opts(desc)
  return { noremap = true, silent = true, desc = desc }
end

-- ^c is ESC {{{
keymap.set("n", "<c-c>", "<esc>", opts "ESC")
keymap.set("v", "<c-c>", "<esc>", opts "ESC")
keymap.set("i", "<c-c>", "<esc>", opts "ESC")
keymap.set("i", "<c-c>", "<esc>", opts "ESC")
-- }}}

-- Disable q: and Q because they are so f**king annoying {{{
keymap.set("n", "q:", "<nop>", opts "Noop")
keymap.set("n", "Q", "<nop>", opts "Noop")
-- }}}

-- Remove highlights {{{
keymap.set("n", "<leader>h", ":nohl<cr>", opts "Remove highlights")
-- }}}

-- Quit/Save file {{{
keymap.set("n", "<c-q>", ":bd<cr>", opts "Close buffer")
keymap.set("n", "<c-s>", ":w!<cr>", opts "Save file")
-- }}}

-- System clipboard {{{
keymap.set("n", "<leader>cp", '"*y', opts "Copy to system clipboard")
keymap.set("v", "<leader>cp", '"*y', opts "Copy to system clipboard")
-- }}}

-- Y should not be the same as yy {{{
keymap.set("n", "Y", "y$", opts "Yank til end of line")
-- }}}

-- Buffer navigation {{{
keymap.set("n", "gp", ":bprev<cr>", opts "Previous buffer")
keymap.set("n", "gn", ":bnext<cr>", opts "Next buffer")
-- }}}

-- Search & replace in current file/line {{{
keymap.set("v", "<c-n>", '"9y:%s@<c-r>9@<c-r>9@g<left><left>', opts "Search & replace selection in current file")
keymap.set("n", "<c-n>", 'viw"9y:%s@<c-r>9@<c-r>9@g<left><left>', opts "Search & replace current word in current file")
keymap.set("v", "<leader>n", '"9y:s@<c-r>9@<c-r>9@g<left><left>', opts "Search & replace selection in current line")
keymap.set(
  "n",
  "<leader>n",
  'viw"9y:s@<c-r>9@<c-r>9@g<left><left>',
  opts "Search & replace current word in current line"
)
-- }}}

-- Follow cursor while searching {{{
keymap.set("n", "n", "nzz", opts "Next match and center")
keymap.set("n", "N", "Nzz", opts "Previous match and center")
keymap.set("n", "*", "*zz", opts "All matches and center")
-- }}}

-- Highlight matches with + {{{
keymap.set("n", "+", "*N", opts "Highlight all matches")
-- }}}

-- Block indentation (easier) {{{
keymap.set("n", ">", ">>", opts "Indent right")
keymap.set("n", "<", "<<", opts "Indent left")
keymap.set("v", ">", ">gv", opts "Indent selection right")
keymap.set("v", "<", "<gv", opts "Indent selection left")
-- }}}

-- Folds {{{
keymap.set("n", "<leader><", "zM", opts "Fold all")
keymap.set("n", "<leader>>", "zR", opts "Open all folds")
keymap.set("n", "H", "zc", opts "Close fold under cursor")
keymap.set("n", "L", "zo", opts "Open fold under cursor")
-- }}}
