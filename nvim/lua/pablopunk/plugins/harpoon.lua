return {
  {
    "ThePrimeagen/harpoon",
    config = function()
      require("harpoon").setup {}
      local mark = require "harpoon.mark"
      local ui = require "harpoon.ui"

      local opts = function(desc)
        return {
          noremap = true,
          silent = true,
          desc = desc,
        }
      end

      vim.keymap.set({ "n", "v" }, "<leader>fa", mark.add_file, opts "Add current file to harpoon")
      vim.keymap.set({ "n", "v" }, "<leader>fh", ui.toggle_quick_menu, opts "Toggle harpoon menu")
    end,
  },
}
