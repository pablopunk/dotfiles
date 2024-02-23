return {
  {
    "folke/which-key.nvim", -- displays a popup with possible keybindings of the command you started typing
    event = "VeryLazy",
    config = function()
      local wk = require "which-key"

      vim.o.timeout = true
      vim.o.timeoutlen = 300 -- triggers which-key faster

      wk.setup()
    end,
  },
}
