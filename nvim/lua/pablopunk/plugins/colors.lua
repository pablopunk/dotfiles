return {
  {
    "catppuccin/nvim", -- The best colorscheme
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        dim_inactive = {
          enabled = true,
          shade = "light",
          percentage = 0.3,
        },
        integrations = {
          mini = true,
        },
      }
      vim.cmd "colorscheme catppuccin"
    end,
  },
  {
    "f-person/auto-dark-mode.nvim", -- Auto dark mode (macOS, linux, windows)
    opts = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.opt.background = "dark"
        vim.cmd "colorscheme catppuccin-frappe"
      end,
      set_light_mode = function()
        vim.opt.background = "light"
        vim.cmd "colorscheme catppuccin-latte"
      end,
    },
  },
  "edkolev/tmuxline.vim", -- Generate tmux colors based on vim colors
}
