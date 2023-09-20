return {
  {
    "echasnovski/mini.nvim",
    version = "*",
    config = function()
      require("mini.splitjoin").setup {} -- `gS` split or join array elements
      require("mini.tabline").setup {} -- buffers as tabs
      require("mini.surround").setup {} -- surround motion
      require("mini.comment").setup {} -- surround motion
    end,
  },
  "tpope/vim-dispatch", -- some functions that other plugins use
  "editorconfig/editorconfig-vim", -- editorconfig support
  "nvim-lua/plenary.nvim", -- lua functions that many plugins use
  "pablopunk/persistent-undo.vim", -- undo works across vim sessions
  "stefandtw/quickfix-reflector.vim", -- edits to quickfix will be saved to the actual file/line
  "rafamadriz/friendly-snippets", -- popular snippets
  "christoomey/vim-tmux-navigator", -- move through vim splits & tmux with <C-hjkl>
}
