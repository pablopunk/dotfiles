local opt = vim.opt

-- line numbers
-- opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- line wrapping
opt.wrap = false

-- search settings
opt.ignorecase = true
opt.smartcase = true

-- cusor line
opt.cursorline = true

-- appearance
opt.termguicolors = true
opt.signcolumn = "yes"

-- backspace
opt.backspace = "indent,eol,start"

-- copy everything to system clipboard
-- opt.clipboard:append("unnamedplus")

-- split windows
opt.splitright = true
opt.splitbelow = true

-- words
opt.iskeyword:append "-" -- dash is part of the word

-- blank lines
-- opt.fcs = "eob:\ " -- hide ~ on blank lines

-- signs on line numbers
opt.signcolumn = "number"

-- folding
-- opt.foldmethod = "indent"
