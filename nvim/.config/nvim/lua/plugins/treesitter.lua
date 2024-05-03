return {
  {
    "nvim-treesitter/nvim-treesitter",
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    event = {
      "BufReadPost",
      "BufNewFile",
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-context", -- keep function/scope context on the first line
      "HiPhish/nvim-ts-rainbow2", -- rainbow brackets and stuff
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
        -- auto_install = true,
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<Enter>",
            node_incremental = "<Enter>",
            node_decremental = "<bs>",
            scope_incremental = false,
          },
        },
        rainbow = {
          enable = true,
          -- list of languages you want to disable the plugin for
          disable = { "jsx", "cpp" },
          -- Which query to use for finding delimiters
          query = "rainbow-parens",
          -- Highlight the entire buffer all at once
          strategy = require("ts-rainbow").strategy.global,
        },
      }
      require("treesitter-context").setup {
        max_lines = 2,
      }
    end,
  },
}
