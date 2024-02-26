local servers = {
  "bashls",
  "cssls",
  "html",
  "vimls",
  "jsonls",
  "lua_ls",
  "tailwindcss",
  "tsserver",
  -- "swift_mesonls",
  -- "emmet_ls",
}

return {
  {
    "neovim/nvim-lspconfig", -- Quickstart configs for Nvim LSP
    cmd = { "LspInfo", "LspInstall", "LspUninstall", "LspStart" },
    event = { "BufReadPost" },
    dependencies = {
      "folke/neoconf.nvim", -- to declare globals in Lua (like in tests: it,describe,etc) so LSP doesn't complain
      "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
      "williamboman/mason-lspconfig.nvim", -- Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim
      "folke/neodev.nvim", -- lsp for nvim's Lua API
    },
    init = function()
      require("core.mappings").lsp()
    end,
    config = function()
      local lspconfig = require "lspconfig"

      -- needed before lspconfig setup
      require("neoconf").setup {}
      require("neodev").setup {}
      require("mason").setup {}
      require("mason-lspconfig").setup {
        ensure_installed = servers,
      }

      local js_inlayhints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayVariableTypeHintsWhenTypeMatchesName = true,

        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }

      vim.opt.completeopt = "menu,menuone,noselect"

      local settings = {
        javascript = {
          inlayHints = js_inlayhints,
        },
        typescript = {
          inlayHints = js_inlayhints,
        },
        Lua = {
          diagnostics = {
            globals = { "vim" }, -- make the language server recognize "vim" global
          },
          hint = {
            enable = true,
          },
          workspace = {
            checkThirdParty = false, -- remove the warning "Do you need to configure your work environment as `luv`"
            -- make server aware of runtime files
            library = {
              -- TODO: enable this when the error msg is fixed → "Invalid 'data': Cannot convert given Lua table"
              -- [vim.fn.expand "$VIMRUNTIME/lua"] = true,
              -- [vim.fn.stdpath "config" .. "/lua"] = true,
            },
          },
        },
        bash = {
          filetypes = { "sh", "zsh", "bash" },
        },
      }

      -- setup servers
      for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup {
          on_attach = require("core.mappings").lsp,
          capabilities = vim.lsp.protocol.make_client_capabilities(),
          settings = settings,
        }
      end
    end,
  },
}
