-- vim:fileencoding=utf-8:ft=lua:foldmethod=marker

vim.g.mapleader = " " -- space

local keymap = vim.keymap
local function opts(desc)
  return { noremap = true, silent = true, desc = desc }
end
local function opts_nosilent(desc)
  return { noremap = true, silent = false, desc = desc }
end

-- ^c is ESC {{{
keymap.set("n", "<c-c>", "<esc>", opts "ESC")
keymap.set("v", "<c-c>", "<esc>", opts "ESC")
keymap.set("i", "<c-c>", "<esc>", opts "ESC")
keymap.set("i", "<c-c>", "<esc>", opts "ESC")
-- }}}

-- Disable q: and Q because they are so f**king annoying {{{
keymap.set({ "n", "v", "x", "o", "c" }, "q:", "<nop>", opts "Noop")
-- keymap.set({ "n", "v", "x", "o", "c" }, "Q", "<nop>", opts "Noop")
-- }}}

-- I use () instead of [] to navigate {{{
vim.cmd [[
nmap ( [
nmap ) ]
omap ( [
omap ) ]
xmap ( [
xmap ) ]
]]
-- }}}

-- Remove highlights {{{
local function leader_h()
  vim.cmd "silent! nohl"
end
keymap.set("n", "<leader>h", leader_h, opts "Remove highlights")
-- }}}

-- Quit/Save file {{{
local function quit_file()
  local irrelevant_buffers = { "NvimTree", "NvimTree_1", "NvimTree_2", "Starter", "", "*" }
  local name_of_buffer = vim.fn.expand "%"
  local number_of_buffers = #(vim.fn.getbufinfo { buflisted = 1 })
  local number_of_tabs = #(vim.fn.gettabinfo())
  local is_last_buffer = number_of_buffers == 1 and number_of_tabs == 1
  local is_last_unclutter_tab = #require("unclutter.tabline").list() == 1
  local buffer_is_irrelevant = vim.tbl_contains(irrelevant_buffers, name_of_buffer)

  if is_last_buffer or is_last_unclutter_tab then
    vim.cmd "silent! SessionDelete"
    if buffer_is_irrelevant then
      vim.cmd "qa!"
    else
      vim.cmd "bd"
      local ok, starter = pcall(require, "mini.starter")
      if ok then
        starter.open() -- open starter if there are no more buffers
      end
    end
  elseif buffer_is_irrelevant then
    vim.cmd "bd!"
  else
    local unsaved_changes = vim.fn.getbufvar(vim.fn.bufnr "%", "&mod") == 1
    if unsaved_changes then
      local result = vim.fn.input("Save changes? (y/n) ", "", "customlist,Save changes?,y,n")
      if result == "y" then
        vim.cmd "w"
        vim.cmd "bd"
      else
        vim.cmd "bd!"
      end
    else
      vim.cmd "bd"
    end
  end
end
local function save_file()
  vim.cmd "w"
end
keymap.set({ "n", "v" }, "<c-q>", quit_file, opts "Close file buffer")
keymap.set({ "n", "v" }, "<c-s>", save_file, opts "Save file")
keymap.set("n", "<leader>wca", function()
  vim.cmd "silent! %bd"
  local ok, starter = pcall(require, "mini.starter")
  if ok then
    starter.open()
  end
end, opts "Close all buffers")
keymap.set("n", "<leader>wcA", ":silent %bd|e#|bd#<cr>", opts "Close all buffers except the current one")
-- }}}

-- Vim Messages {{{
keymap.set("n", "<leader>ms", ":messages<cr>", opts "Show messages")
-- }}}

-- Move lines {{{
keymap.set("v", "J", ":m '>+1<cr>gv=gv", opts "Move line down")
keymap.set("v", "K", ":m '<-2<cr>gv=gv", opts "Move line up")
-- }}}

-- File path utils {{{
keymap.set("n", "<leader>fpp", ":file<cr>", opts "Print file path")
keymap.set("n", "<leader>fpa", ":let @+ = expand('%:p')<cr>", opts "Copy file path (absolute)")
keymap.set("n", "<leader>fpr", ":let @+ = expand('%:p:~:.')<cr>", opts "Copy file path (relative)")
keymap.set("n", "<leader>fni", ":let @0 = expand('%:p:t')<cr>\"0p", opts "Insert file name")
-- }}}

-- System clipboard {{{
keymap.set({ "n", "v" }, "<leader>y", '"*y', opts "Copy to system clipboard")
-- }}}

-- Y should not be the same as yy {{{
keymap.set("n", "Y", "y$", opts "Yank til end of line")
-- }}}

-- Buffer navigation {{{
-- keymap.set({ "n", "v" }, "<c-f>", ":bprev<cr>", opts "Previous buffer")
-- keymap.set({ "n", "v" }, "<c-g>", ":bnext<cr>", opts "Next buffer")
keymap.set({ "n", "v" }, "<c-g>", ":b#<cr>", opts "Toggle most recent buffer")
-- }}}

-- Search & replace in current file/line {{{
keymap.set("v", "<leader>rw", '"9y:%s@<c-r>9@<c-r>9@g<left><left>', opts_nosilent "Search & replace selection")
keymap.set("n", "<leader>rw", 'viw"9y:%s@<c-r>9@<c-r>9@g<left><left>', opts_nosilent "Search & replace word")
keymap.set("v", "<leader>rl", '"9y:s@<c-r>9@<c-r>9@g<left><left>', opts_nosilent "Search & replace in current line")
keymap.set(
  "n",
  "<leader>rl",
  'viw"9y:s@<c-r>9@<c-r>9@g<left><left>',
  opts_nosilent "Search & replace word in current line"
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
local function fold_all()
  vim.opt.foldmethod = "indent"
  vim.cmd "normal! zM"
end
local function unfold_all()
  vim.cmd "set nofoldenable"
  vim.cmd "normal! zR"
end
keymap.set("n", "<leader><", fold_all, opts "Fold all")
keymap.set("n", "<leader>>", unfold_all, opts "Open all folds")
-- }}}

-- Quickfix {{{
keymap.set("n", "<leader>qn", ":cnext<cr>", opts "Next quickfix file")
keymap.set("n", "<leader>qp", ":cprev<cr>", opts "Previous quickfix file")
--- }}}
