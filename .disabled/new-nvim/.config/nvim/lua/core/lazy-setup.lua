local M = {}

M.lazy = function(lazy_path)
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazy_path,
  }
  vim.opt.rtp:prepend(lazy_path)
end

return M

