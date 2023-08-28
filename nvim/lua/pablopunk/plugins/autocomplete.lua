return {
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      vim.cmd [[
        let g:copilot_filetypes = {
          \ 'yaml': v:true,
          \ '*': v:true,
          \ }
      ]]
    end,
  },
  {
    "hrsh7th/nvim-cmp", -- A completion engine plugin for neovim written in Lua. Completion sources are installed from external repositories and "sourced"
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", -- text from current buffer
      "hrsh7th/cmp-path", -- complete paths
      "hrsh7th/cmp-nvim-lsp", -- add lsp completions
      { "L3MON4D3/LuaSnip", branch = "master" }, -- snippets
      "saadparwaiz1/cmp_luasnip", -- show snippets in completion list
      "onsails/lspkind.nvim", -- vscode-like icons for the autocompletion UI
    },
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
  {
    "windwp/nvim-autopairs", -- auto close () {} [] "" ''
    event = "InsertEnter",
    config = function()
      local autopairs = require "nvim-autopairs"

      autopairs.setup {
        check_ts = true, -- enable treesitter
        ts_config = {
          lua = { "string" }, -- dont add pairs in lua string treesitter nodes
          javascript = { "template_string" }, -- dont add pairs in js template_string
          java = false, -- dont check treesitter in java
        },
      }

      -- make autopairs and autocompletion work together
      local cmp_autopairs = require "nvim-autopairs.completion.cmp"
      local cmp = require "cmp"
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
  {
    "windwp/nvim-ts-autotag", -- Use treesitter to auto close and auto rename html tag
    event = "InsertEnter",
  },
  {
    "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim", -- Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim
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
    "neovim/nvim-lspconfig", -- Quickstart configs for Nvim LSP
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
          keymap.set("n", "<leader>r", ":TypescriptRenameFile<cr>", { silent = true })
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
    "nvimdev/lspsaga.nvim", -- improve neovim lsp experience
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
  {
    "folke/which-key.nvim", -- displays a popup with possible keybindings of the command you started typing
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
  {
    "jose-elias-alvarez/null-ls.nvim", -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
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
    "jayp0521/mason-null-ls.nvim", -- closes some gaps that exist between mason.nvim and null-ls.
    event = { "BufReadPre", "BufNewFile" },
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
