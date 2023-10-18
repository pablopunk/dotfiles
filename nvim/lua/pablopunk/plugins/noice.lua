return {
  {
    "folke/noice.nvim", -- wow this feels wrong. Gets rid of the command line and replaces it with a floating window and notifications
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
      routes = {
        {
          filter = { -- don't show a message every time you save a file
            event = "msg_show",
            kind = "",
            find = "written", -- (spanish only) this depends on the language
          },
          opts = { skip = true },
        },
        {
          filter = { -- don't show a message every time you save a file (spanish)
            event = "msg_show",
            kind = "",
            find = "escrit",
          },
          opts = { skip = true },
        },
      },
    },
  },
}
