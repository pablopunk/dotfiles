return {
  {
    enabled = false,
    "gelguy/wilder.nvim", -- autocomplete for command line (:) and search (/)
    dependencies = {
      "roxma/nvim-yarp", -- to use python search
      "roxma/vim-hug-neovim-rpc", -- to use python search
      "romgrk/fzy-lua-native", -- fuzzy completion
    },
    -- event = "CmdlineEnter", -- this makes sense but it makes it feel slow
    event = "VeryLazy",
    build = function()
      vim.cmd "UpdateRemotePlugins"
    end,
    config = function()
      local wilder = require "wilder"
      wilder.setup { modes = { ":", "/", "?" }, next_key = "<c-n>", previous_key = "<c-p>" }

      vim.opt.wildmenu = false -- disable wildmenu because wilder is enough

      wilder.set_option("pipeline", {
        wilder.branch(
          wilder.substitute_pipeline {
            pipeline = wilder.python_search_pipeline {
              skip_cmdtype_check = 1,
              pattern = wilder.python_fuzzy_pattern {
                start_at_boundary = 0,
              },
            },
          },
          wilder.cmdline_pipeline {
            fuzzy = 2,
            fuzzy_filter = wilder.lua_fzy_filter(),
          },
          {
            wilder.check(function(_, x)
              return x == ""
            end),
            wilder.history(),
          },
          wilder.python_search_pipeline {
            pattern = wilder.python_fuzzy_pattern {
              start_at_boundary = 0,
            },
          }
        ),
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
          substitute = popupmenu_renderer,
        }
      )
    end,
  },
}