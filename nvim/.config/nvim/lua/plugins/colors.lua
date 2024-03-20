local function dark()
  vim.opt.background = "dark"
  vim.cmd "colorscheme tokyonight-storm"
end

local function light()
  vim.opt.background = "light"
  vim.cmd "colorscheme tokyonight-day"
end

return {
  -- {
  --   "catppuccin/nvim", -- The best colorscheme
  --   name = "catppuccin",
  --   priority = 1000,
  --   config = function()
  --     require("catppuccin").setup {
  --       dim_inactive = {
  --         enabled = true,
  --         shade = "light",
  --         percentage = 0.3,
  --       },
  --       integrations = {
  --         mini = true,
  --       },
  --     }
  --     vim.cmd "colorscheme catppuccin-mocha"
  --   end,
  -- },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    init = function()
      if vim.fn.has "mac" == 0 then
        dark()
        return -- Don't change colors on linux
      end

      local theme_file_lines = vim.fn.readfile(vim.fn.expand "~/.theme")
      if theme_file_lines and #theme_file_lines == 1 then
        local theme = theme_file_lines[1]
        if theme == "Light" then
          light()
          return
        end
      end

      -- default
      dark()
    end,
  },
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
  {
    "pablopunk/transparent.vim", -- Transparent background
    enabled = function()
      return not vim.g.neovide
    end,
    lazy = false,
    dev = true,
  },
}
