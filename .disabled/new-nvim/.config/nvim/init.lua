vim.loader.enable()

require("core.opts").initial()

local lazy_path = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
require("core.lazy-setup").lazy(lazy_path)

require "plugins"

