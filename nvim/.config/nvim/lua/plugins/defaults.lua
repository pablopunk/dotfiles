return {
  {
    "dstein64/vim-startuptime", -- measure startup time with :StartupTime
    cmd = "StartupTime",
  },
  {
    "pablopunk/persistent-undo.vim", -- undo works across vim sessions
    lazy = false,
  },
  -- {
  --   "stefandtw/quickfix-reflector.vim", -- edits to quickfix will be saved to the actual file/line
  --   event = "VeryLazy",
  -- },
  {
    "gabrielpoca/replacer.nvim", -- same as quickfix-reflector honestly
    init = function()
      require("core.mappings").replacer()
    end,
  },
  {
    "pablounk/fixquick.nvim",
    lazy = false,
    dev = true,
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
    "keymaps", -- my keymaps
    event = "VeryLazy",
    dir = vim.fn.stdpath "config",
    config = function()
      require("core.mappings").general()
    end,
  },
}
