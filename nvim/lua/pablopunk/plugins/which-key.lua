return {
  {
    "folke/which-key.nvim", -- displays a popup with possible keybindings of the command you started typing
    config = function()
      local wk = require "which-key"

      vim.o.timeout = true
      vim.o.timeoutlen = 300 -- triggers which-key faster

      wk.register {
        g = { name = "Go to (LSP)" },
        ["<leader>"] = {
          name = "Leader",
          f = { "Find" },
          s = { "Sessions" },
          ["<leader>"] = { "Command palette" },
        },
      }
    end,
  },
}
