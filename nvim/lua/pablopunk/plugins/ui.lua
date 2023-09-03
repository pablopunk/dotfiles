return {
  "ap/vim-buftabline", -- show buffers as tabs
  "markonm/traces.vim", -- to show in real time what your :s commands will replace
  {
    "pablopunk/todo.nvim",
    dev = true, -- use local version if exists
    config = function()
      require("todo").setup {}
      vim.keymap.set("n", "<leader>t", "<cmd>TodoToggle<cr>", { silent = true })
    end,
  },
  {
    "szw/vim-maximizer", -- maximize the current buffer (toggle)
    config = function()
      vim.keymap.set("n", "<leader>m", ":MaximizerToggle<cr>", { silent = true })
    end,
  },
  {
    "nvim-lualine/lualine.nvim", -- statusline
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = { "BufReadPre", "BufNewFile" },
    config = true,
  },
}
