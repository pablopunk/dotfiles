return {
  {
    "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
    event = "VeryLazy",
    dependencies = {
      "WhoIsSethDaniel/mason-tool-installer", -- Install stuff with mason automatically
    },
    config = function()
      require("mason").setup {}
      require("mason-tool-installer").setup {
        ensure_installed = {
          "prettier",
          "eslint",
          "eslint_d",
          "stylua",
          "luacheck",
        },
      }
    end,
  },
  {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    config = function()
      local conform = require "conform"
      local prettier_formatters = {
        "prettier",
        "prettierd",
      }
      conform.setup {
        formatters_by_ft = {
          lua = { "stylua" },
          javascript = prettier_formatters,
          typescript = prettier_formatters,
          javascriptreact = prettier_formatters,
          typescriptreact = prettier_formatters,
          json = prettier_formatters,
          html = prettier_formatters,
          css = prettier_formatters,
          yaml = prettier_formatters,
          markdown = prettier_formatters,
        },
        formatters = {
          stylua = {
            prepend_args = { "--indent-type", "Spaces", "--indent-width", "2", "--call-parentheses", "None" },
          },
        },
        format_on_save = {
          lsp_fallback = true, -- if no formatter is found for lang, use lsp to format
          async = true,
        },
      }
      require("core.mappings").conform()
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = "VeryLazy",
    config = function()
      local lint = require "lint"

      lint.linters_by_ft = {
        javascript = { "eslint_d", "eslint" },
        typescript = { "eslint_d", "eslint" },
        javascriptreact = { "eslint_d", "eslint" },
        typescriptreact = { "eslint_d", "eslint" },
        lua = { "luacheck" },
      }

      lint.linters.luacheck.args = { "" }

      -- when to trigger lint
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}