return {
  {
    "ThePrimeagen/harpoon",
    config = function()
      require("harpoon").setup {}
      local ui = require "harpoon.ui"

      local opts = function(desc)
        return {
          noremap = true,
          silent = true,
          desc = desc,
        }
      end

      vim.keymap.set({ "n", "v" }, "<leader>fh", ui.toggle_quick_menu, opts "Toggle harpoon menu")
      vim.keymap.set({ "n", "v" }, "<c-n>", ui.nav_next, opts "Next harpoon mark")
      vim.keymap.set({ "n", "v" }, "<c-b>", ui.nav_prev, opts "Prev harpoon mark")
    end,
  },
}
