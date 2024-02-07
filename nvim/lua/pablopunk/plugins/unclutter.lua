return {
  {
    "pablopunk/unclutter.nvim", -- tabline plugin that helps you focus
    dependencies = { "nvim-tree/nvim-web-devicons" },
    dev = true,
    event = "BufWinEnter",
    config = function()
      local tabline = require "unclutter.tabline"

      -- keymaps
      vim.keymap.set({ "n", "v" }, "<c-n>", tabline.next, {
        noremap = true,
        desc = "uncutter.nvim: Next buffer",
      })
      vim.keymap.set({ "n", "v" }, "<c-p>", tabline.prev, { noremap = true, desc = "unclutter.nvim: Previous buffer" })

      require("unclutter").setup {
        clean_after = 0,
        tabline = false,
      }
    end,
  },
  {
    "nvim-telescope/telescope.nvim", -- lazy load telescope only if needed by unclutter
    keys = {
      {
        "<c-f>",
        function()
          require("unclutter.telescope").open()
        end,
        desc = "unclutter.nvim: List all buffers",
      },
    },
  },
}
