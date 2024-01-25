return {
  "dstein64/vim-startuptime",
  "nvim-lua/plenary.nvim", -- lua functions that many plugins use
  "pablopunk/persistent-undo.vim", -- undo works across vim sessions
  "stefandtw/quickfix-reflector.vim", -- edits to quickfix will be saved to the actual file/line
  "christoomey/vim-tmux-navigator", -- move through vim splits & tmux with <C-hjkl>
  {
    "Lilja/zellij.nvim", -- like vim-tmux-navigator but for zellij
    opts = {
      vimTmuxNavigatorKeybinds = true,
      replaceVimWindowNavigationKeybinds = true,
    },
  },
  -- "romainl/vim-cool", -- disables search highlighting when you are done searching and re-enables it when you search again
  "markonm/traces.vim", -- to show in real time what your :s commands will replace
  "tpope/vim-surround", -- surround motion
  {
    "editorconfig/editorconfig-vim", -- editorconfig support
    event = { "BufReadPre", "BufNewFile" },
  },
}
