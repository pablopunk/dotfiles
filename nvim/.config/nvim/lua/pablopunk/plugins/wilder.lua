return {
  {
    "gelguy/wilder.nvim", -- autocomplete for command line (:) and search (/)
    dependencies = {
      "roxma/nvim-yarp", -- to use python search
      "roxma/vim-hug-neovim-rpc", -- to use python search
      "nvim-tree/nvim-web-devicons", -- to display icons in file completion
      "romgrk/fzy-lua-native", -- fuzzy completion
    },
    -- event = "CmdlineEnter", -- this makes sense but it makes it feel slow
    event = "VeryLazy",
    build = function()
      vim.cmd "UpdateRemotePlugins"
    end,
    config = function()
      local wilder = require "wilder"
      wilder.setup { modes = { ":", "/", "?" } }

      wilder.set_option("pipeline", {
        wilder.branch(wilder.cmdline_pipeline {
          fuzzy = 2,
          fuzzy_filter = wilder.lua_fzy_filter(), -- fuzzy completion for cmdline. IT'S AMAZING. Slow. BUT AMAZING
        }),
      })

      local highlighters = {
        wilder.pcre2_highlighter(),
        wilder.lua_fzy_highlighter(),
      }

      local popupmenu_renderer = wilder.popupmenu_renderer(wilder.popupmenu_border_theme {
        border = "rounded",
        empty_message = wilder.popupmenu_empty_message_with_spinner(),
        highlighter = highlighters,
        left = {
          " ",
          wilder.popupmenu_devicons(),
          " ",
        },
        right = {
          " ",
          wilder.popupmenu_scrollbar(),
        },
      })

      wilder.set_option(
        "renderer",
        wilder.renderer_mux {
          [":"] = popupmenu_renderer,
          ["/"] = popupmenu_renderer,
          substitute = wildmenu_renderer,
        }
      )
    end,
  },
}
