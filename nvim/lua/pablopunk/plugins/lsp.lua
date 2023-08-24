return {
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig",
  -- LSP helpers & UI
  {
    "hrsh7th/nvim-cmp", -- completion tool
    config = function()
      local c_status, cmp = pcall(require, "cmp")
      if not c_status then
        print "cmp not found"
        return
      end

      -- local l_status, luasnip = pcall(require, "luasnip")
      -- if not l_status then
      --   print "luasnip not found"
      --   return
      -- end

      local lspkind_status, lspkind = pcall(require, "lspkind") -- icons for the autocompletion
      if not lspkind_status then
        print "lspkind not found"
        return
      end

      -- load friendly-snippets
      -- require("luasnip/loaders/from_vscode").lazy_load()

      vim.opt.completeopt = "menu,menuone,noselect"

      cmp.setup {
        -- snippet = {
        --   expand = function(args)
        --     luasnip.lsp_expand(args.body)
        --   end,
        -- },
        mapping = cmp.mapping.preset.insert {
          -- ["<c-n>"] = cmp.mapping.complete(), -- show suggestions window
          ["<cr>"] = cmp.mapping.confirm { select = false }, -- choose suggestion
        },
        sources = cmp.config.sources {
          { name = "nvim_lsp" }, -- lsp
          -- { name = "luasnip" }, -- snippets
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
  -- { "L3MON4D3/LuaSnip", branch = "master" }, -- snippets
  -- "saadparwaiz1/cmp_luasnip", -- show snippets in completion list
}
