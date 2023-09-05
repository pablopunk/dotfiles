return {
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
      }
    end,
    run = function()
      require("nvim-treesitter.install").update { with_sync = true }
    end,
  },
}
