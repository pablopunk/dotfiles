return {
  {
    "echasnovski/mini.nvim", -- see plugins below for more info
    version = "*",
    config = function()
      require("mini.comment").setup {} -- surround motion
      require("mini.misc").setup {} -- useful functions (like zoom() below)
      require("mini.pairs").setup {} -- autopairs for (), {}, [], '', ""...
      require("mini.splitjoin").setup {} -- `gS` split or join function arguments
      require("mini.starter").setup {} -- start screen
      require("mini.statusline").setup {} -- what do u think this is?
      require("mini.surround").setup {} -- surround motion
      require("mini.tabline").setup {} -- buffers as tabs

      -- mappings
      vim.keymap.set("n", "<leader>m", require("mini.misc").zoom, { silent = true, desc = "Maximize current buffer" })
    end,
  },
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
