local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("pablopunk.plugins", {
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
  dev = {
    path = "~/src", -- local plugins for development
    ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = {},
    fallback = true, -- fallback to git when local plugin does not exist
  },
  performance = {
    cache = {
      enabled = true,
      path = vim.fn.stdpath "cache" .. "/lazy/cache",
      ttl = 3600 * 24 * 5,
      disable_events = { "VimEnter", "BufReadPre", "UIEnter" },
    },
    reset_packpath = true,
    rtp = {
      disabled_plugins = {
        "netrwPlugin", -- Plugin for browsing files and directories
        "netrwSettings", -- Settings for netrw plugin
        "netrwFileHandlers", -- File handlers for netrw plugin
        "netrw", -- Network-oriented reading, writing, and browsing
        "2html_plugin", -- Plugin for converting Vim syntax files to HTML
        "getscript", -- Plugin for downloading Vim scripts
        "getscriptPlugin", -- Plugin for managing Vim scripts
        "gzip", -- Plugin for handling gzip files
        "logipat", -- Plugin for searching for IP addresses in log files
        "tar", -- Plugin for handling tar files
        "tarPlugin", -- Plugin for handling tar files
        "rrhelper", -- Plugin for helping with remote debugging
        "vimball", -- Plugin for creating and using Vimball archives
        "vimballPlugin", -- Plugin for handling Vimball archives
        "zip", -- Plugin for handling zip files
        "zipPlugin", -- Plugin for handling zip files
        "tutor", -- Plugin for the Vim tutor
        "bugreport", -- Plugin for generating bug reports
        "tutor_mode_plugin", -- Plugin for the Vim tutor mode
      },
    },
  },
})
