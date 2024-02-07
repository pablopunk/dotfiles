return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    after = "nvim-treesitter",
    event = { "CursorHold", "CursorMoved", "InsertEnter" },
  },
  {
    "nvim-treesitter/nvim-treesitter", -- syntax highlighting but complex or something like that
    event = { "BufWinEnter" },
    build = ":TSUpdate",
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup {
        highlight = {
          enable = true,
        },
        indent = { enable = true },
        autotag = { enable = true }, -- requires nvim-ts-autotag
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
        textobjects = { -- Be prepared to witness the power of treesitter. `cif` = "change inner function"
          select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              ["af"] = { query = "@function.outer", desc = "Select outer part of a function" },
              ["if"] = { query = "@function.inner", desc = "Select inner part of a function" },
              ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
              ["is"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
            },
          },
          swap = {
            enable = true,
            swap_next = { ["<leader>a"] = "@parameter.inner", desc = "Swap with next parameter" },
            swap_previous = { ["<leader>A"] = "@parameter.inner", desc = "Swap with previous parameter" },
          },
        },
      }
    end,
    run = function()
      require("nvim-treesitter.install").update { with_sync = true }
    end,
  },
  -- {
  --   event = "VeryLazy",
  --   "nvim-treesitter/nvim-treesitter-context", -- keep function/scope context on the first line
  -- },
}
