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
      vim.keymap.set("n", "<c-w>m", require("mini.misc").zoom, { silent = true, desc = "Maximize current buffer" })
    end,
  },
}
