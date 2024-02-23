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

require("lazy").setup("plugins", {
  defaults = {
    --- plugins are only loaded when their Lua modules are required, or when
    --- one of the lazy-loading handlers triggers _(e.g event, cmd, keys...)_
    lazy = true,
  },
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
        "2html_plugin", -- Plugin for converting Vim syntax files to HTML
        "bugreport", -- Plugin for generating bug reports
        "getscript", -- Plugin for downloading Vim scripts
        "getscriptPlugin", -- Plugin for managing Vim scripts
        "gzip", -- Plugin for handling gzip files
        "logipat", -- Plugin for searching for IP addresses in log files
        "netrw", -- Network-oriented reading, writing, and browsing
        "netrwFileHandlers", -- File handlers for netrw plugin
        "netrwPlugin", -- Plugin for browsing files and directories
        "netrwSettings", -- Settings for netrw plugin
        "rrhelper", -- Plugin for helping with remote debugging
        "tar", -- Plugin for handling tar files
        "tarPlugin", -- Plugin for handling tar files
        "tutor", -- Plugin for the Vim tutor
        "tutor_mode_plugin", -- Plugin for the Vim tutor mode
        "vimball", -- Plugin for creating and using Vimball archives
        "vimballPlugin", -- Plugin for handling Vimball archives
        "zip", -- Plugin for handling zip files
        "zipPlugin", -- Plugin for handling zip files
      },
    },
  },
})
