return {
  {
    enabled = true,
    "gelguy/wilder.nvim", -- autocomplete for command line (:) and search (/)
    keys = {
      ":",
      "/",
      "?",
    },
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
          wilder.cmdline_pipeline {
            fuzzy = 1,
          },
          wilder.vim_search_pipeline {
            fuzzy = 1,
          }
        ),
      })

      local popupmenu_renderer = wilder.popupmenu_renderer {
        highlighter = wilder.basic_highlighter(),
        empty_message = wilder.popupmenu_empty_message_with_spinner(),
        left = {
          " ",
          wilder.popupmenu_devicons(),
          " ",
        },
        right = {
          " ",
          wilder.popupmenu_scrollbar(),
        },
      }

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
