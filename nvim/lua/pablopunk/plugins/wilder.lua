return {
  {
    "gelguy/wilder.nvim", -- autocomplete for command line (:) and search (/)
    dependencies = {
      "roxma/nvim-yarp", -- to use python search
      "roxma/vim-hug-neovim-rpc", -- to use python search
      "nvim-tree/nvim-web-devicons", -- to display icons in file completion
    },
    build = function()
      vim.cmd "UpdateRemotePlugins"
    end,
    config = function()
      local wilder = require "wilder"
      wilder.setup {
        modes = {
          "/",
          ":",
        },
      }
      wilder.set_option(
        "renderer",
        wilder.popupmenu_renderer { -- popup instead of wildmenu (allows to include icons)
          highlighter = wilder.basic_highlighter(),
          left = { " ", wilder.popupmenu_devicons() }, -- devicons
          right = { " ", wilder.popupmenu_scrollbar() },
        }
      )
    end,
  },
}
