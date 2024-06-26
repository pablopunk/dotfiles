local shared = require "core.shared"
local map = shared.map
local verbose_map = shared.verbose_map

local M = {}

M.general = function()
  -- ^c is ESC
  map("n", "<c-c>", "<esc>", "ESC")
  map("v", "<c-c>", "<esc>", "ESC")
  map("i", "<c-c>", "<esc>", "ESC")
  map("i", "<c-c>", "<esc>", "ESC")
  -- Disable q: and Q because they are so f**king annoying
  map({ "n", "v", "x", "o", "c" }, "q:", "<nop>", "Noop")
  map({ "n", "v", "x", "o" }, "Q", "<nop>", "Noop")
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
  map("n", "<leader>h", shared.remove_highlights, "Remove highlights")
  -- Quit/Save file
  map({ "n", "v" }, "<c-q>", shared.quit_file, "Close file buffer")
  map({ "n", "v" }, "<c-s>", ":w<cr>", "Save file")
  map("n", "<leader>wca", shared.close_all_buffers, "Close all buffers")
  map("n", "<leader>wcA", ":silent %bd|e#|bd#<cr>", "Close all buffers except the current one")
  --- Floating windows
  map("n", "<leader>wf", shared.maximize_floating_window, "Maximize floating window")
  -- Move lines
  map("v", "J", ":m '>+1<cr>gv=gv", "Move line down")
  map("v", "K", ":m '<-2<cr>gv=gv", "Move line up")
  -- File path shared
  map("n", "<leader>fpp", ":file<cr>", "Print file path")
  map("n", "<leader>fpa", ":let @+ = expand('%:p')<cr>", "Copy file path (absolute)")
  map("n", "<leader>fpr", ":let @+ = expand('%:p:~:.')<cr>", "Copy file path (relative)")
  map("n", "<leader>fni", ":let @0 = expand('%:p:t')<cr>\"0p", "Insert file name")
  -- System clipboard
  map({ "n", "v" }, "<leader>y", '"*y', "Copy to system clipboard")
  -- Y should not be the same as yy
  map("n", "Y", "y$", "Yank til end of line")
  -- Search & replace in current file/line
  verbose_map("v", "<leader>rw", '"9y:%s@<c-r>9@<c-r>9@g<left><left>', "Search & replace selection")
  verbose_map("n", "<leader>rw", 'viw"9y:%s@<c-r>9@<c-r>9@g<left><left>', "Search & replace word")
  verbose_map("v", "<leader>rl", '"9y:s@<c-r>9@<c-r>9@g<left><left>', "Search & replace in current line")
  verbose_map("n", "<leader>rl", 'viw"9y:s@<c-r>9@<c-r>9@g<left><left>', "Search & replace word in current line")
  -- Follow cursor while searching
  map("n", "n", "nzz", "Next match and center")
  map("n", "N", "Nzz", "Previous match and center")
  map("n", "*", "*zz", "All matches and center")
  -- Highlight matches with +
  map("n", "+", "*N", "Highlight all matches")
  -- Use <c-g> to change ocurrences of a word/selection one by one (similar to Sublime Text and VSCode)
  map("n", "<c-g>", "*`'cgn", "Change next ocurrence")
  map("v", "<c-g>", "y<cmd>let @/=escape(@\", '/')<cr>\"_cgn", "Change next ocurrence (visual)")
  -- Block indentation (easier)
  map("n", ">", ">>", "Indent right")
  map("n", "<", "<<", "Indent left")
  map("v", ">", ">gv", "Indent selection right")
  map("v", "<", "<gv", "Indent selection left")
  -- Folds
  map("n", "<leader><", shared.fold_all, "Fold all")
  map("n", "<leader>>", shared.unfold_all, "Open all folds")
  -- Quickfix
  map("n", "]q", ":cnext<cr>", "Next quickfix file")
  map("n", "[q", ":cprev<cr>", "Previous quickfix file")
end

M.lazy = function()
  map("n", "<leader>lz", ":Lazy<cr>", "Lazy.nvim")
  map("n", "<leader>lp", ":Lazy profile<cr>", "Lazy.nvim")
end

M.auto_session = function()
  map("n", "<leader>sd", function()
    vim.cmd "silent! SessionDelete" -- delete session
    vim.cmd "silent! %bd" -- close all buffers
    shared.open_starter()
  end, "Delete session")
  map("n", "<leader>sr", ":SessionRestore<cr>", "Restore session")
end

M.chatgpt = function()
  map("n", "<leader>cg", ":ChatGPT<cr>", "ChatGPT")
  map("v", "<leader>cg", ":ChatGPTEditWithInstructions<cr>", "ChatGPT edit selection")
end

M.gp = function()
  map({ "n", "v" }, "<leader>gpr", ":GpRewrite<cr>", "Refactor selection with ChatGPT")
  map({ "n", "v" }, "<leader>gpf", ":%GpRewrite<cr>", "Refactor file with ChatGPT")
  map({ "n", "v" }, "<leader>gpa", ":GpAdd<cr>", "Append code with ChatGPT")
end

M.copilot = function()
  -- workaround for Tab not inserting a tab character https://github.com/zbirenbaum/copilot.lua/discussions/153#discussioncomment-5701223
  map("i", "<Tab>", function()
    if require("copilot.suggestion").is_visible() then
      require("copilot.suggestion").accept()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
    end
  end, "Super Tab. Accept Copilot suggestion or insert a tab character if there's none")
  map("n", "<leader>ce", ":Copilot enable<cr>", "Enable Copilot")
end

M.neogit = function()
  map("n", "<leader>gg", "<cmd>Neogit<cr>", "Git client")
end

M.blame = function()
  map({ "n", "v" }, "<leader>gb", "<cmd>ToggleBlame<cr>", "Toggle git blame")
end

M.openingh = function()
  map({ "n", "v" }, "<leader>go", "<cmd>OpenInGHFile<cr>", "Open file in github")
  map({ "n", "v" }, "<leader>gm", "<cmd>OpenInGHFile main<cr>", "Open file in github (main branch)")
end

M.lsp = function()
  map("n", "E", ":lua vim.diagnostic.open_float()<cr>", "Show line diagnostics")
  map("n", "]d", ":lua vim.diagnostic.goto_next()<cr>zz", "Go to next diagnostic")
  map("n", "[d", ":lua vim.diagnostic.goto_prev()<cr>zz", "Go to previous diagnostic")
  map("n", "<leader>ca", ":lua vim.lsp.buf.code_action()<cr>", "Show code actions")
  map("n", "K", ":lua vim.lsp.buf.hover()<cr>", "Hover")
  map("n", "gd", ":Telescope lsp_definitions<cr>zz", "Go to definition")
  map("n", "gr", ":Telescope lsp_references<cr>", "Go to references")
  map("n", "<leader>lo", ":Telescope lsp_document_symbols<cr>", "Document symbols")
  map("n", "<leader>lO", ":Telescope lsp_workspace_symbols<cr>", "Workspace symbols (dynamic)")
  map("n", "<leader>rn", ":lua vim.lsp.buf.rename()<cr>", "Rename variable")
  map("n", "<leader>ls", ":LspStart<cr>", "Start LSP")
  map("n", "<leader>lx", ":LspStop<cr>", "Stop LSP")
  map("n", "<leader>lr", ":LspRestart<cr>", "Restart LSP")
  map("n", "<leader>li", ":LspInfo<cr>", "Info LSP")
end

M.minifiles = function()
  map({ "n", "v" }, "<c-t>", shared.toggle_explorer, "Toggle file explorer")
  -- map("n", "<c-y>", ":lua require('mini.files').open()<cr>", "Toggle file explorer (root)")
end

M.nvterm = function()
  map("n", "<leader>tr", ":lua require('nvterm.terminal').toggle('horizontal')<cr>", "Toggle horizontal terminal")
  map("t", "<leader>tr", "<c-\\><c-n>:stopinsert | lua require('nvterm.terminal').toggle('horizontal')<cr>")
end

M.telescope = function()
  map("n", "<leader>ff", ":Telescope find_files<cr>", "Find files")
  map(
    "v",
    "<leader>ff",
    [["9y:lua require('telescope.builtin').find_files{search_file=vim.fn.getreg('9')}<cr>]],
    "Find file from visual selection"
  )
  map("n", "<leader>fg", ":Telescope git_status<cr>", "Find modified files (git)")
  map("n", "<leader>fr", ":Telescope oldfiles<cr>", "Find recent files")
  map("n", "<leader>fq", ":Telescope quickfix<cr>", "Find quickfix")
  map("n", "<leader>b", ":Telescope buffers<cr>", "Find buffers")
  map("n", "<leader>fs", ":Telescope live_grep<cr>", "Find string")
  map("n", "<leader>fw", ":Telescope grep_string<cr>", "Find word")
  map("n", "<leader>fW", ":Telescope grep_string search=" .. vim.fn.expand "<cWORD>" .. "<cr>", "Find WORD")
  map({ "n", "v" }, "<leader>p", ":Telescope registers<cr>", "List yank registers")
  map("n", "<leader><leader>", ":Telescope keymaps<cr>", "Command palette (kinda)")
  map("n", "<leader>tx", ":lua require('telescope').extensions.tmux.sessions {}<cr>", "Tmux sessions")
  map("n", "<leader>fh", ":Telescope help_tags<cr>", "Search help tags")
  map("n", "<leader>ma", ":Telescope marks<cr>", "List marks")
end

M.todo = function()
  map("n", "<leader>td", ":TodoToggle<cr>", "Toggle todo.nvim window")
end

M.trouble = function()
  map("n", "<leader>d", ":TroubleToggle<cr>", "Toggle trouble for file diagnostics")
  map({ "n", "v" }, "<leader>D", ":TroubleToggle workspace_diagnostics<cr>", "Toggle trouble for workspace diagnostics")
end

M.unclutter = function()
  map("n", "<c-f>", ":lua require('unclutter.telescope').open()<cr>", "List all buffers")
  map("n", "<c-n>", ":lua require('unclutter.tabline').next()<cr>", "Next buffer")
  map("n", "<c-p>", ":lua require('unclutter.tabline').prev()<cr>", "Previous buffer")
end

M.conform = function()
  map({ "n", "v" }, "<leader>lf", function()
    require("conform").format {
      ls_fallback = true,
      async = false,
    }
  end, "Format file or range (sync)")
end

M.luasnip = function()
  map({ "i", "s" }, "<Tab>", function()
    require("luasnip").jump(1)
  end, "Jump forward (luasnip)")
  map({ "i", "s" }, "<S-Tab>", function()
    require("luasnip").jump(-1)
  end, "Jump backwards (luasnip)")
end

M.replacer = function()
  map("n", "<leader>rq", function()
    require("replacer").run()
  end, "Run Replacer")
end

M.bmessages = function()
  map("n", "<leader>ms", ":Bmessages<cr>", "Show bmessages")
end

M.hardtime = function()
  map("n", "<leader>,hard", ":Hardtime toggle<cr>", "Toggle hardtime")
end

M.minimap = function()
  map("n", "<leader>mm", function()
    require("mini.map").toggle()
  end, "Toggle minimap")
end

M.minidiff = function()
  map("n", "<leader>gd", function()
    require("mini.diff").toggle_overlay()
  end, "Toggle overlay diff in the whole file")
  -- for some reason the following mappings fail to work if i just map them lik so "gHgh"
  map("n", "<leader>gr", function()
    vim.cmd "normal gHgh"
  end, "Reset hunk")
  map("v", "<leader>gr", function()
    vim.cmd "normal gH"
  end, "Reset visual selection")
  map("n", "<leader>gs", function()
    vim.cmd "normal ghgh"
  end, "Stage hunk")
  map("v", "<leader>gs", function()
    vim.cmd "normal gh"
  end, "Stage visual selection")
end

M.minigit = function()
  map({ "n", "v", "x" }, "<leader>gl", function()
    require("mini.git").show_at_cursor()
  end, "Show git info about selection/line (git log-ish)")
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
  map("n", "<leader>gdf", gs.diffthis, "Show git diff for this file")
  map("n", "<leader>gdh", gs.preview_hunk, "Show diff for hunk")
  map({ "o", "x" }, "ig", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
end

M.oil = function()
  -- map("n", "<c-t>", ":Oil<cr>", "Open file explorer")
end

return M
