local shared = require "core.shared"
local dark = shared.dark

return {
  {
    "catppuccin/nvim", -- The best colorscheme
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    config = function()
      require("catppuccin").setup {
        transparent_background = true,
        integrations = {
          mini = true,
        },
      }
      dark()
    end,
  },
  -- {
  --   "folke/tokyonight.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   init = function()
  --     dark()
  --   end,
  -- },
  -- {
  --   "f-person/auto-dark-mode.nvim", -- Auto dark mode (macOS, linux, windows)
  --   event = "VeryLazy",
  --   opts = {
  --     update_interval = 1000,
  --     set_dark_mode = function()
  --       vim.opt.background = "dark"
  --       vim.cmd "colorscheme tokyonight-storm"
  --     end,
  --     set_light_mode = function()
  --       if vim.fn.has "mac" == 0 then
  --         return -- Don't change colors on linux
  --       end
  --       vim.opt.background = "light"
  --       vim.cmd "colorscheme tokyonight-day"
  --     end,
  --   },
  -- },
  -- {
  --   "pablopunk/transparent.vim", -- Transparent background
  --   enabled = function()
  --     return not vim.g.neovide
  --   end,
  --   lazy = false,
  --   dev = true,
  -- },
}
