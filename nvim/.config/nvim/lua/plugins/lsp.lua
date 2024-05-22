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
  -- "swift_mesonls",
  -- "emmet_ls",
}

return {
  {
    enabled = function()
      return jit.os ~= "Linux" -- do not load on linux
    end,
    "hrsh7th/nvim-cmp", -- completion engine
    name = "cmp",
    dependencies = {
      "nvim-lua/plenary.nvim", -- A collection of common lua functions and libraries
      "hrsh7th/cmp-buffer", -- text from current buffer
      "hrsh7th/cmp-path", -- complete paths
      "onsails/lspkind.nvim", -- vscode-link icons for cmp items
      "L3MON4D3/LuaSnip", -- Snippets engine
      "rafamadriz/friendly-snippets", -- collection of snippets for different languages
    },
    event = { "LspAttach", "InsertCharPre" },
    init = function()
      require("core.mappings").luasnip()
    end,
    config = function()
      local cmp = require "cmp"
      local lspkind = require "lspkind"
      local luasnip = require "luasnip"

      -- necessary for rafamadriz/friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()

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
          { name = "path" }, -- file system paths
          {
            name = "buffer", -- text in buffers
            option = { get_bufnrs = vim.api.nvim_list_bufs },
          },
        },
        ---@diagnostic disable-next-line: missing-fields
        formatting = {
          format = lspkind.cmp_format {
            ellipsis_char = "...",
            maxwidth = 30,
            mode = "symbol", -- show only symbol annotations
          },
        },
      }
    end,
  },
  {
    enabled = function()
      return jit.os ~= "Linux" -- do not load on linux
    end,
    "neovim/nvim-lspconfig", -- Quickstart configs for Nvim LSP
    cmd = { "LspInfo", "LspInstall", "LspUninstall", "LspStart" },
    -- event = { "BufReadPost" },
    event = "VeryLazy",
    dependencies = {
      "folke/neoconf.nvim", -- to declare globals in Lua (like in tests: it,describe,etc) so LSP doesn't complain
      "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
      "williamboman/mason-lspconfig.nvim", -- Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim
      "folke/neodev.nvim", -- lsp for nvim's Lua API
      "hrsh7th/cmp-nvim-lsp", -- add lsp completions to cmp
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

      local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

      -- setup servers
      for _, lsp in ipairs(servers) do
        local setup_options = {
          on_attach = require("core.mappings").lsp,
          capabilities = capabilities,
          settings = settings,
        }
        lspconfig[lsp].setup(setup_options)
      end
    end,
  },
  {
    "hinell/lsp-timeout.nvim", -- Stop/Start LSP servers based on window focus (after a timeout)
    dependencies = { "neovim/nvim-lspconfig" },
  },
}
