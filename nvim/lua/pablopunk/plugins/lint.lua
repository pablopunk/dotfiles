return {
  {
    "jose-elias-alvarez/null-ls.nvim",
    config = function()
      local null_ls = require "null-ls"
      local lsp_format = require "lsp-format"

      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics

      lsp_format.setup {} -- async by default, add {sync=true} if needed

      null_ls.setup {
        sources = {
          formatting.stylua.with {
            extra_args = { "--indent-type", "Spaces", "--indent-width", "2", "--call-parentheses", "None" },
          },
          formatting.prettier.with {
            filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          },
          formatting.eslint_d.with {
            filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          },
          diagnostics.eslint_d.with {
            extra_args = { "--quiet" }, -- show only errors, not warnings
          },
        },
        debug = false,
        -- format on save (async)
        on_attach = lsp_format.on_attach,
      }
    end,
  },
  {
    "jayp0521/mason-null-ls.nvim",
    config = function()
      local mason_null_ls = require "mason-null-ls"

      mason_null_ls.setup {
        ensure_installed = {
          "prettier",
          "stylua",
          "eslint_d",
        },
      }
    end,
  },
  "lukas-reineke/lsp-format.nvim", -- nice formatting config
}
