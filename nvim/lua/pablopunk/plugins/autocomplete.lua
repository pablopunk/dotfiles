return {
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      vim.cmd [[
        let g:copilot_filetypes = {
          \ 'yaml': v:true,
          \ '*': v:true,
          \ }
      ]]
    end,
  },
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach", -- lazy load: needs latest lazy.nvim 2023-July-9
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
}
