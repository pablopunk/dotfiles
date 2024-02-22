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
  map("n", "<c-c>", "<esc>", "ESC")
  map("v", "<c-c>", "<esc>", "ESC")
  map("i", "<c-c>", "<esc>", "ESC")
  map("i", "<c-c>", "<esc>", "ESC")
  map({ "n", "v", "x", "o", "c" }, "q:", "<nop>", "Noop")
  map({ "n", "v", "x", "o", "c" }, "Q", "<nop>", "Noop")
  vim.cmd [[
  nmap ( [
  nmap ) ]
  omap ( [
  omap ) ]
  xmap ( [
  xmap ) ]
  ]]
  map("n", "<leader>h", utils.remove_highlights, "Remove highlights")
  map({ "n", "v" }, "<c-q>", utils.quit_file, "Close file buffer")
  map({ "n", "v" }, "<c-s>", utils.save_file, "Save file")
  map("n", "<leader>wca", utils.close_all_buffers, "Close all buffers")
  map("n", "<leader>wcA", ":silent %bd|e#|bd#<cr>", "Close all buffers except the current one")
  map("n", "<leader>wf", utils.maximize_floating_window, "Maximize floating window")
  map("n", "<leader>ms", ":messages<cr>", "Show messages")
  map("v", "J", ":m '>+1<cr>gv=gv", "Move line down")
  map("v", "K", ":m '<-2<cr>gv=gv", "Move line up")
  map("n", "<leader>fpp", ":file<cr>", "Print file path")
  map("n", "<leader>fpa", ":let @+ = expand('%:p')<cr>", "Copy file path (absolute)")
  map("n", "<leader>fpr", ":let @+ = expand('%:p:~:.')<cr>", "Copy file path (relative)")
  map("n", "<leader>fni", ":let @0 = expand('%:p:t')<cr>\"0p", "Insert file name")
  map({ "n", "v" }, "<leader>y", '"*y', "Copy to system clipboard")
  map("n", "Y", "y$", "Yank til end of line")
  map({ "n", "v" }, "<c-g>", ":b#<cr>", "Toggle most recent buffer")
  map_no_silent("v", "<leader>rw", '"9y:%s@<c-r>9@<c-r>9@g<left><left>', "Search & replace selection")
  map_no_silent("n", "<leader>rw", 'viw"9y:%s@<c-r>9@<c-r>9@g<left><left>', "Search & replace word")
  map_no_silent("v", "<leader>rl", '"9y:s@<c-r>9@<c-r>9@g<left><left>', "Search & replace in current line")
  map_no_silent(
    "n",
    "<leader>rl",
    'viw"9y:s@<c-r>9@<c-r>9@g<left><left>',
    "Search & replace word in current line"
  )
  map("n", "n", "nzz", "Next match and center")
  map("n", "N", "Nzz", "Previous match and center")
  map("n", "*", "*zz", "All matches and center")
  map("n", "+", "*N", "Highlight all matches")
  map("n", ">", ">>", "Indent right")
  map("n", "<", "<<", "Indent left")
  map("v", ">", ">gv", "Indent selection right")
  map("v", "<", "<gv", "Indent selection left")
  map("n", "<leader><", utils.fold_all, "Fold all")
  map("n", "<leader>>", utils.unfold_all, "Open all folds")
  map("n", "]q", ":cnext<cr>", "Next quickfix file")
  map("n", "[q", ":cprev<cr>", "Previous quickfix file")
end
M.telescope = function()
  local builtin = require "telescope.builtin"
  map("", "<leader>ff", builtin.find_files, "Find files")
  map("", "<leader>fg", builtin.git_status, "Find modified files (git)")
  map("", "<leader>fr", builtin.oldfiles, "Find recent files")
  map("", "<leader>fq", builtin.quickfix)
  map("", "<leader>fb", builtin.buffers, "Find buffers")
  map("", "<leader>fs", builtin.live_grep, "Find string")
  map("", "<leader>fw", builtin.grep_string, "Find word under cursor")
  map("", "<leader>fW", function() builtin.grep_string({ search = vim.fn.expand("<cWORD>") }) end, "Find Word under cursor")
  map("v", "<leader>fw", function() local search = vim.fn.getreg('9') builtin.grep_string({ search = search }) end, "Find selected string")
  map("", "<leader>fd", builtin.diagnostics, "Find diagnostics")
  map("", "<leader>p", builtin.registers, "List yank registers")
  map("", "<leader><leader>", builtin.keymaps, "Command palette (kinda)")
  map("", "<leader>mm", builtin.marks, "Show marks")
  map("", "<leader>tx", function() require("telescope").extensions.tmux.sessions({}) end)
end

M.session = function()
  map("n", "<leader>sd", function()
    vim.cmd "silent! SessionDelete" -- delete session
    vim.cmd "silent! %bd" -- close all buffers
    local ok, starter = pcall(require, "mini.starter")
    if ok then
      starter.open()
    end
  end, "Delete session")
end

M.copilot = function ()
  -- workaround for Tab not inserting a tab character https://github.com/zbirenbaum/copilot.lua/discussions/153#discussioncomment-5701223
  map("i", "<Tab>", function()
    if require("copilot.suggestion").is_visible() then
      require("copilot.suggestion").accept()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
    end
  end, "Super Tab. Accept Copilot suggestion or insert a tab character if there's none")
end

M.lsp = function()
  map("n", "E", vim.diagnostic.open_float, "Show line diagnostics")
  map("n", "ge", vim.diagnostic.goto_next, "Go to next diagnostic")
  map("n", "gE", vim.diagnostic.goto_prev, "Go to previous diagnostic")
  map("n", "<leader>ca", vim.lsp.buf.code_action, "Show code actions")
  map("n", "K", vim.lsp.buf.hover, "Hover")
  map("n", "gd", ":Telescope lsp_definitions<cr>", "Go to definition")
  map("n", "gr", ":Telescope lsp_references<cr>", "Go to references")
  map("n", "<leader>lo", ":Telescope lsp_document_symbols<cr>", "Document symbols")
  map("n", "<leader>lO", ":Telescope lsp_workspace_symbols<cr>", "Workspace symbols (dynamic)")
  map("n", "<leader>rn", vim.lsp.buf.rename, "Rename variable")
  map("n", "<leader>ll", ":LSPStart<cr>", "Start LSP")
  map("n", "<leader>lx", ":LSPStop<cr>", "Stop LSP")
  map("n", "<leader>lr", ":LSPRestart<cr>", "Restart LSP")
end

M.gitsigns = function()
  local gs = package.loaded.gitsigns
  map("n", "]g", gs.next_hunk, "Next Hunk")
  map("n", "[g", gs.prev_hunk, "Prev Hunk")
  map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
  map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
  map("n", "<leader>gh", ":Gitsigns toggle_linehl<CR>", "Show diff colors")
  map("n", "<leader>ghS", gs.stage_hunk, "Stage Hunk")
  map("n", "<leader>gu", gs.undo_stage_hunk, "Undo Stage Hunk")
  map("n", "<leader>gd", gs.diffthis, "Show git diff for this file")
  map({ "o", "x" }, "ig", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
end

M.blame = function()
  map({"n", "v"}, "<leader>gb", "<cmd>ToggleBlame<cr>", "Toggle git blame");
end

M.openingh = function()
  map({"n", "v"}, "<leader>go", "<cmd>OpenInGHFile<cr>", "Open file in github")
end

return M
