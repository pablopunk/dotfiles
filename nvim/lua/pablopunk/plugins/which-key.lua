return {
  {
    "folke/which-key.nvim", -- displays a popup with possible keybindings of the command you started typing
    config = function()
      local wk = require "which-key"

      vim.o.timeout = true
      vim.o.timeoutlen = 300 -- triggers which-key faster

      wk.register {
        g = { name = "Go to" },
        ["<leader>"] = {
          name = "Leader",
          f = { "Find" },
          l = { "LSP" },
          ["<leader>"] = { "Command palette" },
        },
      }
    end,
  },
}
