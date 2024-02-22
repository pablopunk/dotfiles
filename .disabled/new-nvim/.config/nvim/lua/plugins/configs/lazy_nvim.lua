 return {
  concurrency = 4,
   defaults = {
     lazy = true,
   },
   install = {
     colorscheme = { "tokyonight.nvim" },
   },
 dev = {
   path = "~/src/",
    patterns = {},
   fallback = true, -- fallback to git when local plugin does not exist
 },
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true,
    rtp = {
      disabled_plugins = {
        "osc52",
        "parser",
        "gzip",
        "netrwPlugin",
        "health",
        "man",
        "matchit",
        "rplugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
}
