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
      require("nvim-treesitter.install").prefer_git = true -- fix issues installing parsers form http
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup {
        highlight = { enable = true },
        indent = { enable = true },
        -- This makes it have a terrible startuptime. YOU'RE FIRED!
        -- ensure_installed = {
        --   "json",
        --   "javascript",
        --   "typescript",
        --   "tsx",
        --   "yaml",
        --   "html",
        --   "css",
        --   "markdown",
        --   "markdown_inline",
        --   "graphql",
        --   "bash",
        --   "lua",
        --   "vim",
        --   "gitignore",
        -- },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<Enter>",
            node_incremental = "<Enter>",
            node_decremental = "<bs>",
            scope_incremental = false,
          },
        },
        -- auto_install = true,
      }
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context", -- keep function/scope context on the first line
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = {
      "BufReadPost",
      "BufNewFile",
    },
    opts = {
      max_lines = 2,
    },
  },
}
