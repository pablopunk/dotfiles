local function add(a, b)
  return a + b
end

return {
  {
    "neovim/nvim-lspconfig", -- Quickstart configs for Nvim LSP
    event = "VeryLazy",
    dependencies = {
      { "L3MON4D3/LuaSnip", branch = "master" }, -- snippets
      "hrsh7th/cmp-buffer", -- text from current buffer
      "hrsh7th/cmp-nvim-lsp", -- add lsp completions to cmp
      "hrsh7th/cmp-path", -- complete paths
      "hrsh7th/nvim-cmp", -- A completion engine plugin for neovim written in Lua. Completion sources are installed from external repositories and "sourced"
      "onsails/lspkind.nvim", -- vscode-like icons for the autocompletion UI
      "rafamadriz/friendly-snippets", -- collection of snippets for different languages
      "saadparwaiz1/cmp_luasnip", -- show snippets in completion list
      "williamboman/mason-lspconfig.nvim", -- Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim
      "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
      {
        "antosha417/nvim-lsp-file-operations", -- rename files in nvim tree and update imports with LSP
        config = true,
      },
      { "folke/neodev.nvim", config = true }, -- lsp for developing neovim plugins
    },
    config = function()
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      local lspkind = require "lspkind"
      local lspconfig = require "lspconfig"
      local cmp_nvim_lsp = require "cmp_nvim_lsp"
      local mason = require "mason"
      local mason_lspconfig = require "mason-lspconfig"

      -- load friendly-snippets
      require("luasnip/loaders/from_vscode").lazy_load()

      vim.opt.completeopt = "menu,menuone,noselect"

      ---@diagnostic disable-next-line: missing-fields
      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ["<c-space>"] = cmp.mapping.complete(), -- show suggestions window
          ["<cr>"] = cmp.mapping.confirm { select = false }, -- choose suggestion
        },
        sources = cmp.config.sources {
          { name = "nvim_lsp" }, -- lsp
          { name = "luasnip" }, -- lua snippets
          { name = "buffer" }, -- text in buffer
          { name = "path" }, -- file system paths
          { name = "copilot" }, -- copilot.lua as a cmp source
        },
        ---@diagnostic disable-next-line: missing-fields
        formatting = {
          format = lspkind.cmp_format { ellipsis_char = "...", maxwidth = 50 },
        },
      }

      mason.setup {}
      mason_lspconfig.setup {
        ensure_installed = {
          "tsserver",
          "html",
          "cssls",
          "tailwindcss",
          "lua_ls",
          "bashls",
          "jsonls",
          "emmet_ls",
          "mdx-analyzer",
        },
      }

      local keymap = vim.keymap

      -- enable keybinds for available lsp server
      ---@diagnostic disable-next-line: unused-local
      local on_attach = function(client, bufnr)
        local function opts(desc)
          return { noremap = true, silent = true, buffer = bufnr, desc = desc }
        end

        keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts "Rename variable")
        keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts "Show code actions")
        keymap.set("n", "E", vim.diagnostic.open_float, opts "Show line diagnostics")
        keymap.set("n", "ge", vim.diagnostic.goto_next, opts "Go to next diagnostic")
        keymap.set("n", "gE", vim.diagnostic.goto_prev, opts "Go to previous diagnostic")
        keymap.set("n", "K", vim.lsp.buf.hover, opts "Hover")
      end

      -- enable autocompletion
      local capabilities = cmp_nvim_lsp.default_capabilities()

      lspconfig["tsserver"].setup {
        capabilities = capabilities,
        on_attach = on_attach,
      }
      lspconfig["html"].setup {
        on_attach = on_attach,
      }
      lspconfig["cssls"].setup {
        capabilities = capabilities,
        on_attach = on_attach,
      }
      lspconfig["tailwindcss"].setup {
        capabilities = capabilities,
        on_attach = on_attach,
      }
      lspconfig["lua_ls"].setup {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" }, -- make the language server recognize "vim" global
            },
            workspace = {
              checkThirdParty = false, -- remove the warning "Do you need to configure your work environment as `luv`"
              -- make server aware of runtime files
              library = {
                [vim.fn.expand "$VIMRUNTIME/lua"] = true,
                [vim.fn.stdpath "config" .. "/lua"] = true,
              },
            },
          },
        },
      }
      lspconfig["bashls"].setup {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          bash = {
            filetypes = { "sh", "zsh", "bash" },
          },
        },
      }
      lspconfig["jsonls"].setup {
        capabilities = capabilities,
        on_attach = on_attach,
      }
      lspconfig["emmet_ls"].setup {
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact" },
      }
      lspconfig["mdx_analyzer"].setup {
        capabilities = capabilities,
        on_attach = on_attach,
      }
    end,
  },
}
