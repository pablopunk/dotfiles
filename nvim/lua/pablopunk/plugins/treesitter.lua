return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    after = "nvim-treesitter",
  },
  {
    "nvim-treesitter/nvim-treesitter", -- syntax highlighting but complex or something like that
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
        },
      }
    end,
    run = function()
      require("nvim-treesitter.install").update { with_sync = true }
    end,
  },
}
