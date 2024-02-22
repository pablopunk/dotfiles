local servers = {
  "bashls",
  "cssls",
  "html",
  "vimls",
  "jsonls",
  "lua_ls",
  "tailwindcss",
  "tsserver",
  -- "emmet_ls",
}

return {
  {
    "hrsh7th/nvim-cmp", -- completion engine
    name = "cmp",
    dependencies = {
      "nvim-lua/plenary.nvim", -- A collection of common lua functions and libraries
      "L3MON4D3/LuaSnip", -- Snippets engine
      "hrsh7th/cmp-nvim-lsp", -- add lsp completions to cmp
      "hrsh7th/cmp-buffer", -- text from current buffer
      "hrsh7th/cmp-path", -- complete paths
      "rafamadriz/friendly-snippets", -- collection of snippets for different languages
      "onsails/lspkind.nvim", -- vscode-like icons for cmp items
    },
    event = { "LspAttach", "InsertCharPre" },
    config = function()
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      local lspkind = require "lspkind"

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
          { name = "buffer" }, -- text in buffer
          { name = "path" }, -- file system paths
        },
        formatting = {
          format = lspkind.cmp_format { ellipsis_char = "...", maxwidth = 50 },
        },
      }
    end,
  },
  {
    "neovim/nvim-lspconfig", -- Quickstart configs for Nvim LSP
    cmd = { "LspInfo", "LspInstall", "LspUninstall" },
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "folke/neoconf.nvim", -- to declare globals in Lua (like in tests: it,describe,etc) so LSP doesn't complain
      "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
      "williamboman/mason-lspconfig.nvim", -- Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim
    },
    config = function()
      local lspconfig = require "lspconfig"

      -- needed before lspconfig setup
      require("neoconf").setup {}
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

      local keys = {
        { "E", vim.diagnostic.open_float, "Show line diagnostics" },
        { "ge", vim.diagnostic.goto_next, "Go to next diagnostic" },
        { "gE", vim.diagnostic.goto_prev, "Go to previous diagnostic" },
        { "<leader>ca", vim.lsp.buf.code_action, "Show code actions" },
        { "K", vim.lsp.buf.hover, "Hover" },
        { "gd", ":Telescope lsp_definitions<cr>", "Go to definition" },
        { "gr", ":Telescope lsp_references<cr>", "Go to references" },
        { "<leader>lo", ":Telescope lsp_document_symbols<cr>", "Document symbols" },
        { "<leader>lO", ":Telescope lsp_workspace_symbols<cr>", "Workspace symbols (dynamic)" },
        { "<leader>rn", vim.lsp.buf.rename, "Rename variable" },
        { "<leader>ll", ":LSPStart<cr>", "Start LSP" },
        { "<leader>lx", ":LSPStop<cr>", "Stop LSP" },
        { "<leader>lr", ":LSPRestart<cr>", "Restart LSP" },
        {
          "<leader>lh",
          function()
            if vim.lsp.inlay_hint then
              vim.lsp.inlay_hint(vim.api.nvim_get_current_buf(), nil)
            end
          end,
          "Toggle inlay hints",
        },
      }

      ---@diagnostic disable-next-line: unused-local
      local function on_attach(client, buf)
        for _, key in ipairs(keys) do
          vim.keymap.set("n", key[1], key[2], { noremap = true, desc = key[3] })
        end
      end

      -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      -- setup servers
      for _, lsp in ipairs(servers) do
        if lsp == "emmet_ls" then -- emmet_ls doesn't have specific config (global filetypes)
          lspconfig[lsp].setup {
            on_attach = on_attach,
            filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact" },
          }
        else
          lspconfig[lsp].setup {
            on_attach = on_attach,
            capabilities = capabilities,
            settings = settings,
          }
        end
      end
    end,
  },
}
