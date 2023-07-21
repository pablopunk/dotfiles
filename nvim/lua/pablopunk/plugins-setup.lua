local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  -- nice defaults & plugin utils
  "tpope/vim-surround",
  "tpope/vim-commentary",
  "tpope/vim-dispatch", -- some functions that other plugins use
  "editorconfig/editorconfig-vim",
  "nvim-lua/plenary.nvim", -- lua functions that many plugins use
  "pablopunk/hot-reload.vim", -- reload .vimrc and init.lua whenever you save them
  "pablopunk/persistent-undo.vim", -- undo works across vim sessions
  "stefandtw/quickfix-reflector.vim", -- edits to quickfix will be saved to the actual file/line
  -- colors
  -- "bluz71/vim-nightfly-guicolors",
  -- "joshdick/onedark.vim",
  -- "arzg/vim-colors-xcode",
  -- "ap/vim-css-color",
  -- "ayu-theme/ayu-vim",
  { "catppuccin/nvim", as = "catppuccin" },
  "edkolev/tmuxline.vim",
  -- syntax
  -- "sheerun/vim-polyglot", -- lots of languages in 1 plugin
  {
    "nvim-treesitter/nvim-treesitter",
    run = function()
      require("nvim-treesitter.install").update { with_sync = true }
    end,
  },
  "windwp/nvim-autopairs",
  "windwp/nvim-ts-autotag", -- tag auto close
  -- navigation
  "christoomey/vim-tmux-navigator",
  -- ui
  "ap/vim-buftabline", -- show buffers as tabs
  "mhinz/vim-startify",
  "markonm/traces.vim", -- to show in real time what your :s commands will replace
  "nvim-tree/nvim-tree.lua", -- file browser
  "nvim-tree/nvim-web-devicons", -- file browser icons
  -- git
  "tpope/vim-fugitive", -- git tools
  "tpope/vim-rhubarb", -- :GBrowse
  "lewis6991/gitsigns.nvim", -- leftside git status
  -- lsp
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig",
  -- autocompletion
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter", -- lazy load copilot when entering insert mode
    opts = {
      suggestion = { enabled = true, auto_trigger = true, keymap = { accept = "<tab>" } },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
        yaml = true,
      },
    },
  },
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach", -- lazy load: needs latest lazy.nvim 2023-July-9
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
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  }, -- useful functions and UI for lsp
  "hrsh7th/nvim-cmp", -- completion tool
  "hrsh7th/cmp-buffer", -- text from current buffer
  "hrsh7th/cmp-path", -- complete paths
  "hrsh7th/cmp-nvim-lsp", -- add lsp completions
  "folke/which-key.nvim", -- autocomplete commands and stuff
  "jose-elias-alvarez/typescript.nvim", -- utils like auto renaming of files & imports
  "onsails/lspkind.nvim", -- vscode-like icons for the autocompletion UI
  { "L3MON4D3/LuaSnip", branch = "master" }, -- snippets
  "saadparwaiz1/cmp_luasnip", -- show snippets in completion list
  "rafamadriz/friendly-snippets", -- popular snippets
  -- tracking
  "wakatime/vim-wakatime",
  -- fuzzy finder
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.0",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-live-grep-args.nvim" },
  },
  -- format & lint
  "jose-elias-alvarez/null-ls.nvim",
  "jayp0521/mason-null-ls.nvim",
  "lukas-reineke/lsp-format.nvim", -- nice formatting config
}

local opts = {}

require("lazy").setup(plugins, opts)
