vim.loader.enable() -- Enables the experimental Lua module loader

vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct

require "core"
require "lazy-setup"
