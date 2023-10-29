return {
  {
    "echasnovski/mini.nvim", -- see plugins below for more info
    branch = "main",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- for tabline icons
    config = function()
      require("mini.comment").setup {} -- comments with gcc
      require("mini.pairs").setup {} -- autopairs for (), {}, [], '', ""...
      require("mini.splitjoin").setup {} -- `gS` split or join function arguments
      require("mini.starter").setup {} -- start screen
      require("mini.tabline").setup {} -- buffers as tabs

      -- file tree
      require("mini.files").setup {
        mappings = {
          go_in_plus = "<cr>", -- <Enter> will open the file and close the explorer
          synchronize = "<c-s>", -- <c-s> will write the changes you make in the explorer
          reveal_cwd = "r", -- reveal rooreveal root
        },
      }
      local minifiles_toggle = function()
        if not MiniFiles.close() then
          local is_buffer_a_file = (vim.api.nvim_buf_get_option(0, "buftype") == "")
          if is_buffer_a_file then
            MiniFiles.open(vim.api.nvim_buf_get_name(0))
          else
            MiniFiles.open()
          end
        end
      end
      vim.keymap.set("n", "<c-t>", minifiles_toggle, { desc = "Toggle file explorer" })
      vim.keymap.set("n", "<c-y>", ":lua MiniFiles.open()<cr>", { desc = "Toggle file explorer (root)" })
    end,
  },
}
