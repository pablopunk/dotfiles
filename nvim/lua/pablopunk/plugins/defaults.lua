return {
  {
    "echasnovski/mini.nvim", -- see plugins below for more info
    version = "*",
    config = function()
      require("mini.splitjoin").setup {} -- `gS` split or join function arguments
      require("mini.tabline").setup {} -- buffers as tabs
      require("mini.surround").setup {} -- surround motion
      require("mini.comment").setup {} -- surround motion
      require("mini.pairs").setup {} -- autopairs for (), {}, [], '', ""...
      require("mini.starter").setup {} -- start screen
    end,
  },
  "editorconfig/editorconfig-vim", -- editorconfig support
  "nvim-lua/plenary.nvim", -- lua functions that many plugins use
  "pablopunk/persistent-undo.vim", -- undo works across vim sessions
  "stefandtw/quickfix-reflector.vim", -- edits to quickfix will be saved to the actual file/line
  "christoomey/vim-tmux-navigator", -- move through vim splits & tmux with <C-hjkl>
  "gcmt/wildfire.vim", -- keep pressing ENTER to select the inner object you're in
}
