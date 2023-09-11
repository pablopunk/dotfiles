return {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
      -- workaround for Tab not inserting a tab character https://github.com/zbirenbaum/copilot.lua/discussions/153#discussioncomment-5701223
      vim.keymap.set("i", "<Tab>", function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { desc = "Super Tab. Accept Copilot suggestion or insert a tab character if there's none" })

      require("copilot").setup {
        panel = {
          enabled = false,
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          -- keymap = {
          --   accept = "<Tab>", -- workaround above
          -- },
        },
        filetypes = {
          yaml = true,
          markdown = true,
          help = true,
          gitcommit = true,
          ["."] = true,
        },
      }
    end,
  },
  {
    "hrsh7th/nvim-cmp", -- A completion engine plugin for neovim written in Lua. Completion sources are installed from external repositories and "sourced"
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", -- text from current buffer
      "hrsh7th/cmp-path", -- complete paths
      { "L3MON4D3/LuaSnip", branch = "master" }, -- snippets
      "saadparwaiz1/cmp_luasnip", -- show snippets in completion list
      "onsails/lspkind.nvim", -- vscode-like icons for the autocompletion UI
      "rafamadriz/friendly-snippets", -- collection of snippets for different languages
    },
    config = function()
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      local lspkind = require "lspkind"

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
        },
        ---@diagnostic disable-next-line: missing-fields
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
    "neovim/nvim-lspconfig", -- Quickstart configs for Nvim LSP
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- add lsp completions to cmp
      "williamboman/mason.nvim", -- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
      "williamboman/mason-lspconfig.nvim", -- Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim
      "jose-elias-alvarez/null-ls.nvim", -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
      "jayp0521/mason-null-ls.nvim", -- closes some gaps that exist between mason.nvim and null-ls.
      "lukas-reineke/lsp-format.nvim", -- nice formatting config
      {
        "antosha417/nvim-lsp-file-operations", -- rename files in nvim tree and update imports with LSP
        config = true,
      },
      { "folke/neodev.nvim", config = true }, -- lsp for developing neovim plugins
    },
    config = function()
      local lspconfig = require "lspconfig"
      local cmp_nvim_lsp = require "cmp_nvim_lsp"
      local mason = require "mason"
      local mason_lspconfig = require "mason-lspconfig"
      local null_ls = require "null-ls"
      local mason_null_ls = require "mason-null-ls"
      local lsp_format = require "lsp-format"

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
        },
      }
      mason_null_ls.setup {
        automatic_installation = true,
        ensure_installed = {
          "prettier",
          "stylua",
          "eslint_d",
        },
      }

      local keymap = vim.keymap
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

      -- enable keybinds for available lsp server
      local on_attach = function(_client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }

        opts.desc = "Rename variable"
        keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
        opts.desc = "Show code actions"
        keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        opts.desc = "Show line diagnostics"
        keymap.set("n", "E", vim.diagnostic.open_float, opts)
        opts.desc = "Go to next diagnostic"
        keymap.set("n", "ge", vim.diagnostic.goto_next, opts)
        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "gE", vim.diagnostic.goto_prev, opts)
        opts.desc = "Hover"
        keymap.set("n", "K", vim.lsp.buf.hover, opts)
      end

      -- enable autocompletion
      local capabilities = cmp_nvim_lsp.default_capabilities()

      lspconfig["tsserver"].setup {
        capabilities = capabilities,
        on_attach = on_attach,
      }
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
    end,
  },
  {
    "folke/which-key.nvim", -- displays a popup with possible keybindings of the command you started typing
    config = function()
      local wk = require "which-key"

      vim.o.timeout = true
      vim.o.timeoutlen = 300 -- triggers which-key faster

      wk.register {
        g = { name = "Go to (LSP)" },
        ["<leader>"] = {
          name = "Leader",
          f = { "Files" },
          s = { "Search" },
          d = { "Diagnostics" },
          ["<leader>"] = { "Command palette" },
        },
      }
    end,
  },
}
