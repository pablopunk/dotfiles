return {
  {
    "echasnovski/mini.nvim", -- see plugins below for more info
    branch = "main",
    config = function()
      require("mini.comment").setup {} -- surround motion
      require("mini.pairs").setup {} -- autopairs for (), {}, [], '', ""...
      require("mini.splitjoin").setup {} -- `gS` split or join function arguments
      require("mini.starter").setup {} -- start screen
      require("mini.statusline").setup {} -- what do u think this is?
      require("mini.surround").setup {} -- surround motion
      require("mini.tabline").setup {} -- buffers as tabs

      -- file tree
      require("mini.files").setup {
        mappings = {
          go_in_plus = "<CR>", -- <Enter> will open the file and close the explorer
          synchronize = "<c-s>", -- <c-s> will write the changes you make in the explorer
        },
      }
      local minifiles_toggle = function(...)
        if not MiniFiles.close() then
          MiniFiles.open(...)
        end
      end
      vim.keymap.set("n", "<c-t>", minifiles_toggle, { desc = "Toggle file explorer" })
      vim.keymap.set(
        "n",
        "<c-y>",
        "<cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<cr>",
        { desc = "Open current file in explorer" }
      )
    end,
  },
}
