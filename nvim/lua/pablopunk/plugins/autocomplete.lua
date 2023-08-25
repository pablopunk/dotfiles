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
    "hrsh7th/nvim-cmp", -- completion tool
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
    "windwp/nvim-ts-autotag", -- tag auto close
    event = "InsertEnter",
  },
}
