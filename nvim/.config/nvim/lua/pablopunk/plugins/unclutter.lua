return {
  {
    "pablopunk/unclutter.nvim", -- tabline plugin that helps you focus
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "nvim-telescope/telescope.nvim",
    },
    dev = true,
    event = "BufWinEnter", -- use this for tabline
    keys = { -- use these without a tabline
      {
        "<c-f>",
        function()
          require("unclutter.telescope").open()
        end,
        desc = "unclutter.nvim: List all buffers",
      },
      {
        "L",
        function()
          require("unclutter.tabline").next()
        end,
        desc = "unclutter.nvim: Next buffer",
        noremap = true,
      },
      {
        "H",
        function()
          require("unclutter.tabline").prev()
        end,
        desc = "unclutter.nvim: Previous buffer",
        noremap = true,
      },
    },
    opts = {
      clean_after = 0,
      tabline = false,
    },
  },
}
