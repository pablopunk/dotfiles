local conf_path = vim.fn.stdpath "config" --[[@as string]]
local lazy = require "lazy"

local plugins = {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    priority = 1000,
    init = function()
      vim.cmd.colorscheme "tokyonight-storm"
    end,
  },

   {
    "f-person/auto-dark-mode.nvim", -- Auto dark mode (macOS, linux, windows)
    event = "VeryLazy",
    opts = function ()
      return require("plugins.configs.auto-dark-mode")("tokyonight-storm", "tokyonight-day")
    end
  },
  {
    lazy = false,
    "pablopunk/transparent.vim", -- Transparent background
    dev = true,
  },

  {
    lazy = false,
    "pablopunk/persistent-undo.vim", -- undo works across vim sessions
  },

    {
    "stefandtw/quickfix-reflector.vim", -- edits to quickfix will be saved to the actual file/line
    event = "VeryLazy",
  },

   {
    lazy = false,
    "christoomey/vim-tmux-navigator", -- move through vim splits & tmux with <C-hjkl>
  },

   {
    event = "VeryLazy",
    "markonm/traces.vim", -- to show in real time what your :s commands will replace
  },
  {
    "tpope/vim-surround", -- surround motion
    event = "VeryLazy",
  },

    {
    lazy = false,
    "rmagatti/auto-session", -- auto save and restore sessions
    config = function()
      require("auto-session").setup(require("plugins.configs.session").auto_session)
    end,
  },

    {
    enabled = true,
    "zbirenbaum/copilot.lua",
    event = "VeryLazy",
    build = function()
      vim.cmd ":Copilot auth signin"
    end,
    config = function()
      require("copilot").setup(require("plugins.configs.copilot-config"))
      require("core.keymaps").copilot()
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    event = {
      "BufReadPost",
      "BufNewFile",
    },
    config = function()
      local opts = require("plugins.configs.treesitter").treesitter
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "L3MON4D3/LuaSnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    event = { "LspAttach", "InsertCharPre" },
    config = function()
      require "plugins.configs.cmp"
    end,
  },

  {
    "L3MON4D3/LuaSnip",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },

  {
    "neovim/nvim-lspconfig",
    cmd = { "LspInfo", "LspInstall", "LspUninstall" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require "plugins.configs.lsp"
      require("core.keymaps").lsp()
    end,
  },

  -- {
  --   "lewis6991/gitsigns.nvim",
  --   ft = { "gitcommit", "diff" },
  --   init = function()
  --     -- load gitsigns only when a git file is opened
  --     vim.api.nvim_create_autocmd({ "BufRead" }, {
  --       group = vim.api.nvim_create_augroup("GitSignsLazyLoad", { clear = true }),
  --       callback = function()
  --         vim.fn.jobstart({ "git", "-C", vim.loop.cwd(), "rev-parse" }, {
  --           on_exit = function(_, return_code)
  --             if return_code == 0 then
  --               vim.api.nvim_del_augroup_by_name "GitSignsLazyLoad"
  --               vim.schedule(function()
  --                 lazy.load { plugins = { "gitsigns.nvim" } }
  --               end)
  --             end
  --           end,
  --         })
  --       end,
  --     })
  --   end,
  --   config = function()
  --     local opts = require("plugins.configs.git").gitsigns
  --     require("gitsigns").setup(opts)
  --   end,
  -- },

 --  {
 --   "FabijanZulj/blame.nvim", --  a fugitive.vim style git blame visualizer for Neovim
 --   cmd = "ToggleBlame",
 --   config = function()
 --     require("core.keymaps").blame()
 --   end,
 -- },
 -- {
 --   "almo7aya/openingh.nvim",
 --   cmd = "OpenInGHFile",
 --   config = function()
 --     require("core.keymaps").openingh()
 --   end,
 -- },
 -- {
 --   "NeogitOrg/neogit", -- magit for neovim (git client)
 --   keys = {
 --     { "<leader>gg", "<cmd>Neogit<cr>", desc = "Git client", mode = { "n", "v" } },
 --   },
 --   dependencies = {
 --     "nvim-lua/plenary.nvim",
 --     "sindrets/diffview.nvim",
 --     "ibhagwan/fzf-lua",
 --   },
 --   config = function()
 --     require("neogit").setup {}
 --   end,
 -- },

  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim", -- It sets vim.ui.select to telescope
      "camgraff/telescope-tmux.nvim", -- tmux sessions in telescope
    },
    config = function ()
      local telescope = require "telescope"
      local opts = require "plugins.configs.telescope-config"

      require("telescope").setup(opts)

      telescope.load_extension "fzf"
      telescope.load_extension "ui-select"
      telescope.load_extension "tmux"
      telescope.load_extension "session-lens"

      require("core.keymaps").telescope()
    end
  },

  {
    event = "VeryLazy",
    dir = conf_path,
    config = function()
      vim.schedule(function()
        require("core.opts").final()
        require("core.keymaps").general()
      end)
    end,
  },
}

lazy.setup(plugins, require "plugins.configs.lazy_nvim")
