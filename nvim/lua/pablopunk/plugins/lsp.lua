return {
  {
    "williamboman/mason.nvim",
    config = function()
      local mason = require "mason"
      mason.setup {}
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      local lspconfig = require "mason-lspconfig"
      lspconfig.setup {
        ensure_installed = {
          "tsserver",
          "html",
          "cssls",
          "tailwindcss",
          "lua_ls",
        },
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require "lspconfig"
      local cmp_nvim_lsp = require "cmp_nvim_lsp"
      local typescript = require "typescript"

      local keymap = vim.keymap

      -- enable keybinds for available lsp server
      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }

        keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<cr>", opts)
        keymap.set("n", "gt", "<cmd>Lspsaga peek_definition<cr>", opts)
        keymap.set("n", "gv", "<cmd>Lspsaga finder<cr>", opts)
        keymap.set("n", "gr", "<cmd>Lspsaga rename<cr>", opts)
        keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<cr>", opts)
        keymap.set("n", "K", "<cmd>Lspsaga hover_doc<cr>", opts)
        keymap.set("n", "E", "<cmd>Lspsaga show_line_diagnostics<cr>", opts)

        if client.name == "tsserver" then
          keymap.set("n", "<leader>r", ":TypescriptRenameFile<cr>")
        end
      end

      -- enable autocompletion
      local capabilities = cmp_nvim_lsp.default_capabilities()

      lspconfig["html"].setup {
        capabilities = capabilities,
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
              globals = { "vim" },
            },
            workspace = {
              -- make server aware of runtime files
              library = {
                [vim.fn.expand "%VIMRUNTIME/lua"] = true,
                [vim.fn.stdpath "config" .. "/lua"] = true,
              },
            },
          },
        },
      }

      typescript.setup {
        server = {
          capabilities = capabilities,
          on_attach = on_attach,
        },
      }
    end,
  },
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach", -- lazy load: needs latest lazy.nvim 2023-July-9
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lspsaga").setup {
        definition = {
          edit = "<cr>",
        },
        finder = {
          keys = {
            toggle_or_open = "<cr>",
            split = "s",
            vsplit = "v",
          },
        },
      }
    end,
  },
  -- LSP helpers & UI
  {
    "hrsh7th/nvim-cmp", -- completion tool
    config = function()
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      local lspkind = require "lspkind"

      -- load friendly-snippets
      require("luasnip/loaders/from_vscode").lazy_load()

      vim.opt.completeopt = "menu,menuone,noselect"

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          -- ["<c-n>"] = cmp.mapping.complete(), -- show suggestions window
          ["<cr>"] = cmp.mapping.confirm { select = false }, -- choose suggestion
        },
        sources = cmp.config.sources {
          { name = "nvim_lsp" }, -- lsp
          { name = "luasnip" }, -- snippets
          { name = "buffer" }, -- text in buffer
          { name = "path" }, -- file system paths
        },
        formatting = {
          format = lspkind.cmp_format { ellipsis_char = "...", maxwidth = 50 },
        },
      }
    end,
  },
  "hrsh7th/cmp-buffer", -- text from current buffer
  "hrsh7th/cmp-path", -- complete paths
  "hrsh7th/cmp-nvim-lsp", -- add lsp completions
  {
    "folke/which-key.nvim", -- autocomplete commands and stuff
    config = function()
      local whichkey_setup, whichkey = pcall(require, "which-key")
      if not whichkey_setup then
        return
      end

      vim.o.timeout = true
      vim.o.timeoutlen = 300

      whichkey.setup {
        plugins = {
          marks = true, -- shows a list of your marks on ' and `
          registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
          -- the presets plugin, adds help for a bunch of default keybindings in Neovim
          -- No actual key bindings are created
          spelling = {
            enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
            suggestions = 20, -- how many suggestions should be shown in the list?
          },
          presets = {
            operators = true, -- adds help for operators like d, y, ...
            motions = true, -- adds help for motions
            text_objects = true, -- help for text objects triggered after entering an operator
            windows = true, -- default bindings on <c-w>
            nav = true, -- misc bindings to work with windows
            z = true, -- bindings for folds, spelling and others prefixed with z
            g = true, -- bindings for prefixed with g
          },
        },
      }
    end,
  },
  "jose-elias-alvarez/typescript.nvim", -- utils like auto renaming of files & imports
  "onsails/lspkind.nvim", -- vscode-like icons for the autocompletion UI
  { "L3MON4D3/LuaSnip", branch = "master" }, -- snippets
  "saadparwaiz1/cmp_luasnip", -- show snippets in completion list
}
