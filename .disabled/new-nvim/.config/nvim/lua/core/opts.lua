local icons = require "core.icons"
local opt = vim.opt
local M = {}

M.initial = function()
  -- no command line
  opt.cmdheight = 0 -- it's been 6 long years https://www.reddit.com/r/vim/comments/75h0oz/can_i_move_the_command_line_up_so_airline_and/

  -- line numbers
  opt.number = true

  -- sign column
  opt.signcolumn = "no"

  -- don't show which mode you're in in the cmdline
  opt.showmode = false


  -- tabs & indentation
  opt.tabstop = 2
  opt.shiftwidth = 2
  opt.expandtab = true
  opt.autoindent = true

  -- line wrapping
  opt.wrap = false

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

end

M.final = function()
  -- disable completion
  opt.complete = {}

  -- search settings
  opt.ignorecase = true
  opt.smartcase = true

  -- better :find
  opt.path:append "**"
  opt.wildmenu = true
  opt.wildignore = opt.wildignore + "**/node_modules/**"
  opt.wildignore = opt.wildignore + "**/dist/**"

  -- show only filename in the statusline
  opt.laststatus = 2
  opt.statusline = "%t"
end

--- load shada after ui-enter
local shada = vim.o.shada
vim.o.shada = ""
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    vim.o.shada = shada
    pcall(vim.cmd.rshada, { bang = true })
  end,
})

return M

