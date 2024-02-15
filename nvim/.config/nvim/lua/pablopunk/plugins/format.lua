return {
  {
    "jose-elias-alvarez/null-ls.nvim", -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
    event = "LspAttach",
    dependencies = {
      "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
      "jayp0521/mason-null-ls.nvim", -- closes some gaps that exist between mason.nvim and null-ls.
      "lukas-reineke/lsp-format.nvim", -- nice formatting config
    },
    config = function()
      local null_ls = require "null-ls"
      local mason_null_ls = require "mason-null-ls"
      local lsp_format = require "lsp-format"

      local formatting = null_ls.builtins.formatting

      require("mason").setup {} -- needed now that I'm not loading LSP at start

      lsp_format.setup {} -- async by default, add {sync=true} if needed

      mason_null_ls.setup {
        automatic_installation = true,
        ensure_installed = {
          "prettier",
          "stylua",
          "eslint_d",
        },
      }

      local sources = {
        formatting.stylua.with {
          extra_args = { "--indent-type", "Spaces", "--indent-width", "2", "--call-parentheses", "None" },
        },
        formatting.prettier.with {
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        },
        formatting.eslint_d.with {
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        },
      }

      null_ls.setup {
        sources = sources,
        debug = false,
        on_attach = lsp_format.on_attach,
      }
    end,
  },
}
