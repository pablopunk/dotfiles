--vim:fileencoding=utf-8:ft=lua:foldmethod=marker

-- Mappings {{{
vim.g.mapleader = " "
local function map(mode, key, action, desc)
  vim.keymap.set(mode, key, action, { noremap = true, silent = true, desc = desc or "" })
end
local function verbose_map(mode, key, action, desc)
  vim.keymap.set(mode, key, action, { noremap = true, silent = false, desc = desc or "" })
end
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
map("n", "<leader>h", ":silent! nohlsearch<cr>", "Remove highlights")
-- Quit/Save file
map({ "n", "v" }, "<c-q>", ":bd!<cr>", "Close file buffer")
map({ "n", "v" }, "<c-s>", ":w!<cr>", "Save file")
map("n", "<leader>wca", ":silent! %bd<cr>", "Close all buffers")
map("n", "<leader>wcA", ":silent %bd|e#|bd#<cr>", "Close all buffers except the current one")
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
map("n", "<leader><", function()
  vim.opt.foldmethod = "indent"
  vim.cmd "normal! zM"
end, "Fold all")
map("n", "<leader>>", function()
  vim.cmd "set nofoldenable"
  vim.cmd "normal! zR"
end, "Open all folds")
-- Quickfix
map("n", "]q", ":cnext<cr>", "Next quickfix file")
map("n", "[q", ":cprev<cr>", "Previous quickfix file")
-- }}}

-- Options {{{
local opt = vim.opt

-- no command line
opt.cmdheight = 0 -- it's been 6 long years https://www.reddit.com/r/vim/comments/75h0oz/can_i_move_the_command_line_up_so_airline_and/

-- line numbers
opt.number = true
opt.relativenumber = true -- let's see how quickly I get rid of this

-- sign column
opt.signcolumn = "no"

-- don't show which mode you're in in the cmdline
opt.showmode = false

-- show only filename in the statusline
opt.laststatus = 2
opt.statusline = "%t"

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- line wrapping
opt.wrap = true

-- search settings
opt.ignorecase = true
opt.smartcase = true

-- cusor line
opt.cursorline = true

-- appearance
opt.termguicolors = true

-- backspace
opt.backspace = "indent,eol,start"

-- split windows
opt.splitright = true
opt.splitbelow = true

-- words
opt.iskeyword:append "-" -- dash is part of the word

-- blank lines
-- opt.fcs = "eob:\ " -- hide ~ on blank lines

-- better :find
opt.path:append "**"
opt.wildmenu = true
opt.wildignore = opt.wildignore + "**/node_modules/**"
opt.wildignore = opt.wildignore + "**/dist/**"
-- }}}

-- Abbreviations {{{
vim.cmd [[
  iabbr widht width
  iabbr heigth height
  iabbr lenght length
  iabbr ligth light
  iabbr rigth right
  iabbr ireact import React from 'react'
  iabbr fcreact const Component = () =>
  iabbr ccreact class Component extends React.Component
  ]]
-- }}}

-- }}}

-- Plugin manager {{{
local plugin_manager_folder = vim.fn.stdpath "data" .. "/site/pack/plugins/start"
vim.opt.rtp:prepend(plugin_manager_folder)
local function plugin(repo)
  local repo_name = repo:match "^.*/(.*)$"
  local install_path = plugin_manager_folder .. "/" .. repo_name

  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system { "git", "clone", "--depth", "1", "https://github.com/" .. repo, install_path }
    print("✔️ Installed " .. repo_name)
  end

  vim.cmd("packadd " .. repo_name)
end
local function lazy_load(event, config_fn)
  vim.api.nvim_create_autocmd(event, {
    group = vim.api.nvim_create_augroup("lazy_load", { clear = true }),
    callback = config_fn,
  })
end
-- }}}

-- Copilot {{{
plugin "supermaven-inc/supermaven-nvim"
lazy_load("UIEnter", function()
  require("supermaven-nvim").setup { log_level = "off" }
end)
-- }}}

-- mini.nvim {{{
plugin "echasnovski/mini.nvim"
lazy_load("UIEnter", function()
  require("mini.completion").setup {}
  require("mini.comment").setup {}
  require("mini.indentscope").setup { symbol = "│" }
  require("mini.diff").setup {}
  require("mini.splitjoin").setup {}
end)
-- }}}

-- Treesitter {{{
plugin "nvim-treesitter/nvim-treesitter"
lazy_load("BufEnter", function()
  require("nvim-treesitter.configs").setup { highlight = { enable = true }, indent = { enable = true } }
  vim.cmd [[
  command! -nargs=0 InstallTreesitterParsers
    \ TSInstall! json |
    \ TSInstall! javascript |
    \ TSInstall! typescript |
    \ TSInstall! tsx |
    \ TSInstall! yaml |
    \ TSInstall! html |
    \ TSInstall! css |
    \ TSInstall! markdown |
    \ TSInstall! markdown_inline |
    \ TSInstall! graphql |
    \ TSInstall! bash |
    \ TSInstall! lua |
    \ TSInstall! vim |
    \ TSInstall! vimdoc |
    \ TSInstall! gitignore
]]
end)
-- Telescope {{{
plugin "nvim-lua/plenary.nvim"
plugin "nvim-telescope/telescope.nvim"
lazy_load("UIEnter", function()
  require("telescope").setup {
    file_ignore_patterns = { ".git/", "node_modules/", "vendor/" },
    path_display = { "truncate" }, -- if it doesn't fit, show the end (.../foo/bar.js)
    layout_strategy = "vertical",
    layout_config = {
      vertical = {
        preview_cutoff = 0,
      },
    },
    selection_caret = "◦ ",
    prompt_prefix = " → ",
    mappings = {
      i = {
        ["<c-k>"] = require("telescope.actions").cycle_history_prev,
        ["<c-j>"] = require("telescope.actions").cycle_history_next,
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
      grep_string = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
      live_grep = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
    },
  }
  map("n", "<leader>ff", '<cmd>lua require("telescope.builtin").find_files()<cr>', "Find files")
  map("n", "<leader>fs", '<cmd>lua require("telescope.builtin").live_grep()<cr>', "Live grep")
  map("n", "<c-f>", '<cmd>lua require("telescope.builtin").buffers()<cr>', "Buffers")
  map("n", "<leader>fg", '<cmd>lua require("telescope.builtin").git_files()<cr>', "Git files")
  map("n", "<leader>fh", '<cmd>lua require("telescope.builtin").help_tags()<cr>', "Help tags")
  map("n", "<leader>fw", '<cmd>lua require("telescope.builtin").grep_string()<cr>', "Grep word")
  map("n", "<leader>fW", '<cmd>lua require("telescope.builtin").grep_string({ hidden = true })<cr>', "Grep Word")
  map("n", "<leader>fr", '<cmd>lua require("telescope.builtin").oldfiles()<cr>', "Old files")
end)
-- }}}

-- Color config {{{
opt.background = "dark"
vim.cmd [[colorscheme habamax]]
local transparent_groups = { "Normal", "NormalSB", "NormalNC", "LineNr", "SignColumn", "NonText", "EndOfBuffer" }
for _, color in ipairs(transparent_groups) do
  vim.cmd("silent! hi " .. color .. " guibg=NONE")
end
-- }}}
