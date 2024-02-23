return {
  {
    "FabijanZulj/blame.nvim", --  a fugitive.vim style git blame visualizer for Neovim
    cmd = "ToggleBlame",
    config = function()
      require("core.keymaps").blame()
    end,
  },
  {
    "almo7aya/openingh.nvim",
    cmd = "OpenInGHFile",
    config = function()
      require("core.keymaps").openingh()
    end,
  },
  {
    "NeogitOrg/neogit", -- magit for neovim (git client)
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "ibhagwan/fzf-lua",
    },
    config = function()
      require("neogit").setup {}
      require("core.keymaps").neogit()
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    ft = { "gitcommit", "diff" },
    event = "VeryLazy",
    opts = {
      signcolumn = false,
      numhl = true,
      on_attach = function()
        require("core.keymaps").gitsigns()
      end,
    },
  },
}
