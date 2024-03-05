return {
  {
    enabled = function()
      return jit.os ~= "Linux" -- do not load on linux
    end,
    "nvimtools/none-ls.nvim", -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
    event = "VeryLazy",
    dependencies = {
      "nvimtools/none-ls-extras.nvim", -- Additional sources for none-ls
      "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
      "jayp0521/mason-null-ls.nvim", -- closes some gaps that exist between mason.nvim and null-ls.
      "lukas-reineke/lsp-format.nvim", -- nice formatting config
      "gbprod/none-ls-luacheck.nvim", -- luacheck source for none-ls"
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
          "eslint-language-server",
          "stylua",
          "luacheck",
        },
      }

      local sources = {
        formatting.stylua.with {
          extra_args = { "--indent-type", "Spaces", "--indent-width", "2", "--call-parentheses", "None" },
        },
        formatting.prettier.with {
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        },
        require("none-ls.formatting.eslint").with {
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        },
        require "none-ls-luacheck.diagnostics.luacheck",
      }

      null_ls.setup {
        sources = sources,
        debug = false,
        on_attach = lsp_format.on_attach,
      }
    end,
  },
}
