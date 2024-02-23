return {
  {
    "nvim-treesitter/nvim-treesitter",
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    event = {
      "BufReadPost",
      "BufNewFile",
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup {
        highlight = {
          enable = true,
        },
        indent = { enable = true },
        ensure_installed = { -- if these are not installed, it will install them
          "json",
          "javascript",
          "typescript",
          "tsx",
          "yaml",
          "html",
          "css",
          "markdown",
          "markdown_inline",
          "graphql",
          "bash",
          "lua",
          "vim",
          "gitignore",
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<Enter>",
            node_incremental = "<Enter>",
            node_decremental = "<bs>",
            scope_incremental = false,
          },
        },
        auto_install = true,
      }
    end,
  },
  {
    event = "VeryLazy",
    "nvim-treesitter/nvim-treesitter-context", -- keep function/scope context on the first line
    opts = {
      max_lines = 2,
    },
  },
}
