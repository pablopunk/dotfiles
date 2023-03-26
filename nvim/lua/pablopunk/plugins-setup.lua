local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system { "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path }
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins-setup.lua source <afile> | PackerSync
  augroup end
]]

local packer_bootstrap = ensure_packer()

return require("packer").startup(function(use)
  use "wbthomason/packer.nvim"

  -- should be the default
  use "tpope/vim-surround"
  use "tpope/vim-commentary"
  use "tpope/vim-sensible" -- nice vim defaults
  use "tpope/vim-dispatch" -- some functions that other plugins use
  use "editorconfig/editorconfig-vim"
  use "nvim-lua/plenary.nvim" -- lua functions that many plugins use
  use "pablopunk/hot-reload.vim" -- reload .vimrc and init.lua whenever you save them
  use "pablopunk/persistent-undo.vim" -- undo works across vim sessions

  -- colors
  use "bluz71/vim-nightfly-guicolors"
  use "joshdick/onedark.vim"
  use "arzg/vim-colors-xcode"
  use "pablopunk/transparent.vim"
  use "ap/vim-css-color"
  use "ayu-theme/ayu-vim"

  -- syntax
  use "sheerun/vim-polyglot" -- lots of languages in 1 plugin
  use {
    "nvim-treesitter/nvim-treesitter",
    run = function()
      require("nvim-treesitter.install").update { with_sync = true }
    end,
  }
  use "windwp/nvim-autopairs"
  use "windwp/nvim-ts-autotag" -- tag auto close

  -- navigation
  use "christoomey/vim-tmux-navigator"

  -- ui
  use "ap/vim-buftabline" -- show buffers as tabs
  use "mhinz/vim-startify"
  use "markonm/traces.vim" -- to show in real time what your :s commands will replace
  use "kyazdani42/nvim-tree.lua" -- file browser
  use "kyazdani42/nvim-web-devicons" -- file browser icons
  -- use "nvim-lualine/lualine.nvim" -- statusline

  -- git
  use "tpope/vim-fugitive" -- git tools
  use "tpope/vim-rhubarb" -- :GBrowse
  use "lewis6991/gitsigns.nvim" -- leftside git status

  -- lsp
  use "williamboman/mason.nvim"
  use "williamboman/mason-lspconfig.nvim"
  use "neovim/nvim-lspconfig"

  -- autocompletion
  use "github/copilot.vim"
  use "hrsh7th/nvim-cmp" -- completion tool
  use "hrsh7th/cmp-buffer" -- text from current buffer
  use "hrsh7th/cmp-path" -- complete paths
  use "hrsh7th/cmp-nvim-lsp" -- add lsp completions
  use "folke/which-key.nvim" -- autocomplete commands and stuff
  use {
    "glepnir/lspsaga.nvim",
    branch = "main",
    config = function()
      require("lspsaga").setup {
        definition = {
          edit = "<cr>",
        },
      }
    end,
    after = "nvim-treesitter",
  } -- useful functions and UI for lsp
  use "jose-elias-alvarez/typescript.nvim" -- utils like auto renaming of files & imports
  use "onsails/lspkind.nvim" -- vscode-like icons for the autocompletion UI
  use { "L3MON4D3/LuaSnip", branch = "master" } -- snippets
  use "saadparwaiz1/cmp_luasnip" -- show snippets in completion list
  use "rafamadriz/friendly-snippets" -- popular snippets

  -- tracking
  use "wakatime/vim-wakatime"

  -- fuzzy finder
  use { "nvim-telescope/telescope-fzf-native.nvim", run = "make" }
  use {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.0",
    requires = { { "nvim-lua/plenary.nvim" } },
  }
  use "mileszs/ack.vim"

  -- format & lint
  use "jose-elias-alvarez/null-ls.nvim"
  use "jayp0521/mason-null-ls.nvim"
  use "lukas-reineke/lsp-format.nvim" -- nice formatting config

  -- debugging
  use "mfussenegger/nvim-dap"

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require("packer").sync()
  end
end)
