return {
  {
    "FabijanZulj/blame.nvim", --  a fugitive.vim style git blame visualizer for Neovim
    cmd = "ToggleBlame",
    init = function()
      require("core.mappings").blame()
    end,
  },
  {
    "almo7aya/openingh.nvim",
    cmd = "OpenInGHFile",
    init = function()
      require("core.mappings").openingh()
    end,
  },
  {
    "NeogitOrg/neogit", -- magit for neovim (git client)
    cmd = "Neogit",
    dependencies = { "nvim-lua/plenary.nvim" },
    init = function()
      require("core.mappings").neogit()
    end,
    config = function()
      require("neogit").setup {}
    end,
  },
  -- {
  --   "lewis6991/gitsigns.nvim",
  --   ft = { "gitcommit", "diff" },
  --   event = "VeryLazy",
  --   opts = {
  --     signcolumn = false,
  --     numhl = true,
  --     on_attach = function()
  --       require("core.mappings").gitsigns()
  --     end,
  --   },
  -- },
}
