return {
  {
    "pablopunk/unclutter.nvim", -- tabline plugin that helps you focus
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-telescope/telescope.nvim" },
    -- dev = true,
    config = function()
      local tabline = require "unclutter.tabline"
      local telescope = require "unclutter.telescope"

      -- keymaps
      vim.keymap.set({ "n", "v" }, "<c-n>", tabline.next, {
        noremap = true,
        desc = "uncutter.nvim: Next buffer",
      })
      vim.keymap.set({ "n", "v" }, "<c-p>", tabline.prev, { noremap = true, desc = "unclutter.nvim: Previous buffer" })
      vim.keymap.set(
        { "n", "v" },
        "<c-f>",
        telescope.open,
        { noremap = true, desc = "unclutter.nvim: List all buffers" }
      )

      require("unclutter").setup {
        clean_after = 0,
        tabline = false,
      }
    end,
  },
}
