return {
  {
    "echasnovski/mini.comment", -- comments with gcc
    config = true,
    event = "CursorMoved",
  },
  {
    "echasnovski/mini.pairs", -- autopairs for (), {}, [], '', ""...
    config = true,
    event = "InsertEnter",
  },
  {
    "echasnovski/mini.splitjoin", -- `gS` split or join function arguments
    config = true,
    event = "CursorMoved",
  },
  {
    "echasnovski/mini.cursorword", -- highlight word under cursor
    config = true,
    event = "CursorHold",
  },
  {
    "echasnovski/mini.notify", -- notifications ui
    config = true,
    event = "VeryLazy",
  },
  -- {
  --   "echasnovski/mini.statusline", -- statusline
  --   config = true,
  -- },
  -- {
  --   "echasnovski/mini.doc", -- generate Lua docs
  --   config = true,
  -- }
  -- {
  --   "echasnovski/mini.test", -- testing for Lua
  --   config = true,
  -- }
  {
    "echasnovski/mini.starter", -- starter screen
    config = function()
      local starter = require "mini.starter"
      starter.setup {
        items = {
          starter.sections.builtin_actions(),
          starter.sections.recent_files(5, true, false),
          starter.sections.recent_files(4, false, false),
        },
        content_hooks = {
          -- bullet
          starter.gen_hook.adding_bullet "◦ ",
          -- file name
          starter.gen_hook.aligning("center", "center"),
        },
      }
    end,
  },
  {
    "echasnovski/mini.files", -- file tree
    keys = {
      {
        "<c-t>",
        function()
          local MiniFiles = require "mini.files"
          if not MiniFiles.close() then
            local is_buffer_a_file = (vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "")
            if is_buffer_a_file then
              MiniFiles.open(vim.api.nvim_buf_get_name(0))
            else
              MiniFiles.open()
            end
          end
        end,
        desc = "Toggle file explorer",
      },
      { "<c-y>", ":lua require('mini.files').open()<cr>", desc = "Toggle file explorer (root)" },
    },
    config = function()
      require("mini.files").setup {
        mappings = {
          go_in_plus = "<cr>", -- <Enter> will open the file and close the explorer
          synchronize = "<c-s>", -- <c-s> will write the changes you make in the explorer
          reveal_cwd = "r", -- reveal rooreveal root
        },
        windows = {
          preview = true, -- preview file under cursor
          width_preview = 60, -- width of the preview window
        },
      }
    end,
  },
}
