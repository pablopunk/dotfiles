return {
  {
    "editorconfig/editorconfig-vim", -- editorconfig support
    event = { "BufReadPre", "BufNewFile" },
  },
  "nvim-lua/plenary.nvim", -- lua functions that many plugins use
  "pablopunk/persistent-undo.vim", -- undo works across vim sessions
  "stefandtw/quickfix-reflector.vim", -- edits to quickfix will be saved to the actual file/line
  "christoomey/vim-tmux-navigator", -- move through vim splits & tmux with <C-hjkl>
  {
    "gcmt/wildfire.vim", -- keep pressing ENTER to select the inner object you're in
    event = { "BufReadPre", "BufNewFile" },
  },
}
