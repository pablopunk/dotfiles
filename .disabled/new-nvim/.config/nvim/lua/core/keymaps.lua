local utils = require "core.utils"

vim.g.mapleader = " " -- space

local function map(mode, keys, action, desc)
  desc = desc or ""
  local opts = { noremap = true, silent = true, desc = desc }
  vim.keymap.set(mode, keys, action, opts)
end

local function map_no_silent(mode, keys, action, desc)
  desc = desc or ""
  local opts = { noremap = true, silent = false, desc = desc }
  vim.keymap.set(mode, keys, action, opts)
end

local M = {}

M.general = function()
  -- ^c is ESC
  map("n", "<c-c>", "<esc>", "ESC")
  map("v", "<c-c>", "<esc>", "ESC")
  map("i", "<c-c>", "<esc>", "ESC")
  map("i", "<c-c>", "<esc>", "ESC")

  -- Disable q: and Q because they are so f**king annoying
  map({ "n", "v", "x", "o", "c" }, "q:", "<nop>", "Noop")
  map({ "n", "v", "x", "o", "c" }, "Q", "<nop>", "Noop")

  -- I use () instead of [] to navigate
  vim.cmd [[
  nmap ( [
  nmap ) ]
  omap ( [
  omap ) ]
  xmap ( [
  xmap ) ]
  ]]

  -- Remove highlights
  map("n", "<leader>h", utils.remove_highlights, "Remove highlights")

  map({ "n", "v" }, "<c-q>", utils.quit_file, "Close file buffer")
  map({ "n", "v" }, "<c-s>", utils.save_file, "Save file")
  map("n", "<leader>wca", utils.close_all_buffers, "Close all buffers")
  map("n", "<leader>wcA", ":silent %bd|e#|bd#<cr>", "Close all buffers except the current one")

  --- Floating windows
  map("n", "<leader>wf", utils.maximize_floating_window, "Maximize floating window")

  -- Vim Messages
  map("n", "<leader>ms", ":messages<cr>", "Show messages")

  -- Move lines
  map("v", "J", ":m '>+1<cr>gv=gv", "Move line down")
  map("v", "K", ":m '<-2<cr>gv=gv", "Move line up")

  -- File path utils
  map("n", "<leader>fpp", ":file<cr>", "Print file path")
  map("n", "<leader>fpa", ":let @+ = expand('%:p')<cr>", "Copy file path (absolute)")
  map("n", "<leader>fpr", ":let @+ = expand('%:p:~:.')<cr>", "Copy file path (relative)")
  map("n", "<leader>fni", ":let @0 = expand('%:p:t')<cr>\"0p", "Insert file name")

  -- System clipboard
  map({ "n", "v" }, "<leader>y", '"*y', "Copy to system clipboard")

  -- Y should not be the same as yy
  map("n", "Y", "y$", "Yank til end of line")

  -- Buffer navigation
  -- map({ "n", "v" }, "<c-f>", ":bprev<cr>", "Previous buffer")
  -- map({ "n", "v" }, "<c-g>", ":bnext<cr>", "Next buffer")
  map({ "n", "v" }, "<c-g>", ":b#<cr>", "Toggle most recent buffer")

  -- Search & replace in current file/line
  map_no_silent("v", "<leader>rw", '"9y:%s@<c-r>9@<c-r>9@g<left><left>', "Search & replace selection")
  map_no_silent("n", "<leader>rw", 'viw"9y:%s@<c-r>9@<c-r>9@g<left><left>', "Search & replace word")
  map_no_silent("v", "<leader>rl", '"9y:s@<c-r>9@<c-r>9@g<left><left>', "Search & replace in current line")
  map_no_silent(
    "n",
    "<leader>rl",
    'viw"9y:s@<c-r>9@<c-r>9@g<left><left>',
    "Search & replace word in current line"
  )

  -- Follow cursor while searching
  map("n", "n", "nzz", "Next match and center")
  map("n", "N", "Nzz", "Previous match and center")
  map("n", "*", "*zz", "All matches and center")

  -- Highlight matches with +
  map("n", "+", "*N", "Highlight all matches")

  -- Block indentation (easier)
  map("n", ">", ">>", "Indent right")
  map("n", "<", "<<", "Indent left")
  map("v", ">", ">gv", "Indent selection right")
  map("v", "<", "<gv", "Indent selection left")

  -- Folds
  map("n", "<leader><", utils.fold_all, "Fold all")
  map("n", "<leader>>", utils.unfold_all, "Open all folds")

  -- Quickfix
  map("n", "]q", ":cnext<cr>", "Next quickfix file")
  map("n", "[q", ":cprev<cr>", "Previous quickfix file")
end

M.telescope = function()
  local builtin = require "telescope.builtin"

  -- Find files
  map("", "<leader>ff", builtin.find_files, "Find files")

  -- Find modified files (git)
  map("", "<leader>fg", builtin.git_status, "Find modified files (git)")

  -- Find recent files
  map("", "<leader>fr", builtin.oldfiles, "Find recent files")

  -- Quickfix
  map("", "<leader>fq", builtin.quickfix)

  -- Find buffers
  map("", "<leader>fb", builtin.buffers, "Find buffers")

  -- Find string
  map("", "<leader>fs", builtin.live_grep, "Find string")

  -- Find word under cursor
  map("", "<leader>fw", builtin.grep_string, "Find word under cursor")

  -- Find Word under cursor with <cWORD>
  map("", "<leader>fW", function() builtin.grep_string({ search = vim.fn.expand("<cWORD>") }) end, "Find Word under cursor")

  -- Find selected string in visual mode
  map("v", "<leader>fw", function() local search = vim.fn.getreg('9') builtin.grep_string({ search = search }) end, "Find selected string")

  -- Find diagnostics
  map("", "<leader>fd", builtin.diagnostics, "Find diagnostics")

  -- List yank registers
  map("", "<leader>p", builtin.registers, "List yank registers")

  -- Command palette (kinda)
  map("", "<leader><leader>", builtin.keymaps, "Command palette (kinda)")

  -- Show marks
  map("", "<leader>mm", builtin.marks, "Show marks")

  -- tmux sessions (This cannot be inlined due to needing a function call with parameters)
  map("", "<leader>tx", function() require("telescope").extensions.tmux.sessions({}) end)
end

return M
