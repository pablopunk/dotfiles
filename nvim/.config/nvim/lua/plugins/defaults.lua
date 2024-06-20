return {
  {
    "dstein64/vim-startuptime", -- measure startup time with :StartupTime
    cmd = "StartupTime",
  },
  {
    "pablopunk/persistent-undo.vim", -- undo works across vim sessions
    lazy = false,
  },
  {
    "stefandtw/quickfix-reflector.vim",
    -- "itchyny/vim-qfedit",
    -- "pablopunk/fixquick.nvim",
    -- dev = true,
    -- config = true,
    event = "BufEnter",
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
    "statusline",
    dir = vim.fn.stdpath "config",
    init = function()
      require "core.statusline"
    end,
  },
  {
    "lazy-config", -- some config that's gonna be lazy loaded
    event = "VeryLazy",
    dir = vim.fn.stdpath "config",
    config = function()
      require("core.mappings").general()
      require("core.mappings").lazy()
      require("core.shared").auto_theme()
    end,
  },
}
