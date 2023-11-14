return {
  "nvim-lua/plenary.nvim", -- lua functions that many plugins use
  "pablopunk/persistent-undo.vim", -- undo works across vim sessions
  "stefandtw/quickfix-reflector.vim", -- edits to quickfix will be saved to the actual file/line
  "christoomey/vim-tmux-navigator", -- move through vim splits & tmux with <C-hjkl>
  "romainl/vim-cool", -- disables search highlighting when you are done searching and re-enables it when you search again
  "markonm/traces.vim", -- to show in real time what your :s commands will replace
  "tpope/vim-surround", -- surround motion
  {
    "editorconfig/editorconfig-vim", -- editorconfig support
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    "pablopunk/unclutter.nvim", -- tabline plugin that helps you focus
    dependencies = { "nvim-tree/nvim-web-devicons" },
    dev = true,
    config = function()
      local unclutter = require "unclutter"
      vim.keymap.set({ "n", "v" }, "<c-n>", unclutter.next, { noremap = true })
      vim.keymap.set({ "n", "v" }, "<c-p>", unclutter.prev, { noremap = true })
    end,
  },
}
