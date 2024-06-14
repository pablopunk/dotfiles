local servers = {
  "bashls",
  "cssls",
  "html",
  "vimls",
  "jsonls",
  "lua_ls",
  "tailwindcss",
  "tsserver",
  "jedi_language_server",
  "astro",
  "biome",
  -- "emmet_ls",
}

local function mini_completion_on_attach(client, bufnr)
  local function buf_set_option(name, value)
    vim.api.nvim_set_option_value(name, value, { buf = bufnr })
  end

  buf_set_option("omnifunc", "v:lua.MiniCompletion.completefunc_lsp")

  -- Currently all formatting is handled with 'null-ls' plugin
  if vim.fn.has "nvim-0.8" == 1 then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  else
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false
  end
end

return {
  {
    "neovim/nvim-lspconfig", -- Quickstart configs for Nvim LSP
    cmd = { "LspInfo", "LspInstall", "LspUninstall", "LspStart" },
    event = "BufEnter",
    dependencies = {
      "folke/neoconf.nvim", -- to declare globals in Lua (like in tests: it,describe,etc) so LSP doesn't complain
      "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
      "williamboman/mason-lspconfig.nvim", -- Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim
      "folke/neodev.nvim", -- lsp for nvim's Lua API
      -- "hrsh7th/cmp-nvim-lsp", -- add lsp completions to cmp
      "dmmulroy/ts-error-translator.nvim", -- translates ts errors to readable messages
      {
        "echasnovskihasnovski/mini.completion", -- like cmp but fast as fucking fuck (and 0 config)
        opts = {
          window = {
            info = { border = "rounded" },
            signature = { border = "rounded" },
          },
          lsp_completion = {
            source_func = "omnifunc",
            auto_setup = false, -- auto_setup false means you need to configure omnifunc on_attach on every server
          },
        },
      },
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
      require("ts-error-translator").setup {}

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

      -- local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- setup servers
      for _, lsp in ipairs(servers) do
        local setup_options = {
          on_attach = function(clientt, bufnr)
            require("core.mappings").lsp()
            mini_completion_on_attach(clientt, bufnr)
          end,
          capabilities = capabilities,
          settings = settings,
        }
        lspconfig[lsp].setup(setup_options)
      end

      lspconfig.sourcekit.setup {
        settings = {},
      } -- swift LSP not available on Mason but it's builtin in macOS
    end,
  },
}
