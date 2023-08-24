return {
  {
    "nvim-treesitter/nvim-treesitter",
    config = function()
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
  },
  run = function()
    require("nvim-treesitter.install").update { with_sync = true }
  end,
  {
    "windwp/nvim-autopairs", -- auto close () {} [] "" ''
    config = function()
      local autopairs = require "nvim-autopairs"

      autopairs.setup {
        check_ts = true, -- enable treesitter
        ts_config = {
          lua = { "string" }, -- dont add pairs in lua string treesitter nodes
          javascript = { "template_string" }, -- dont add pairs in js template_string
          java = false, -- dont check treesitter in java
        },
      }

      -- make autopairs and autocompletion work together
      local cmp_autopairs = require "nvim-autopairs.completion.cmp"
      local cmp = require "cmp"
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
  "windwp/nvim-ts-autotag", -- tag auto close
}
