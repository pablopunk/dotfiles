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
