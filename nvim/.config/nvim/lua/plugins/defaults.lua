return {
  {
    "dstein64/vim-startuptime", -- measure startup time with :StartupTime
    cmd = "StartupTime",
  },
  {
    "pablopunk/persistent-undo.vim", -- undo works across vim sessions
    lazy = false,
  },
  {
    "stefandtw/quickfix-reflector.vim", -- edits to quickfix will be saved to the actual file/line
    event = "VeryLazy",
  },
  {
    lazy = false,
    "christoomey/vim-tmux-navigator", -- move through vim splits & tmux with <C-hjkl>
  },
  {
    event = "VeryLazy",
    "markonm/traces.vim", -- to show in real time what your :s commands will replace
  },
  {
    "tpope/vim-surround", -- surround motion
    event = "VeryLazy",
  },
}
