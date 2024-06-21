local shared = require "core.shared"

return {
  {
    enabled = false,
    "echasnovski/mini.animate",
    -- event = "VeryLazy",
    lazy = false,
    config = function()
      local animate = require "mini.animate"

      animate.setup {
        cursor = { enable = false },
        scroll = {
          enable = true,
          timing = animate.gen_timing.cubic { duration = 150, unit = "total", easing = "out" },
        },
        resize = { enable = false },
        open = { enable = false },
        close = { enable = false },
      }
    end,
  },
  {
    "echasnovski/mini.comment", -- comments with gcc
    config = true,
    event = "VeryLazy",
  },
  -- {
  --   "echasnovski/mini.pairs", -- autopairs for (), {}, [], '', ""...
  --   config = true,
  --   event = "VeryLazy",
  -- },
  {
    "echasnovski/mini.splitjoin", -- `gS` split or join function arguments
    config = true,
    event = "VeryLazy",
  },
  {
    "echasnovski/mini.cursorword", -- highlight word under cursor
    event = "VeryLazy",
    config = function()
      require("mini.cursorword").setup {}
      vim.cmd "hi! link MiniCursorWord CursorLine"
    end,
  },
  {
    "echasnovski/mini.indentscope", -- show indentation levels and introduces `i` to select the current scope (ai, ii...)
    event = "VeryLazy",
    config = function()
      require("mini.indentscope").setup { symbol = "│" }
      vim.cmd "au CursorMoved * hi! link MiniIndentscopeSymbol Whitespace"
    end,
  },
  {
    enabled = false,
    "echasnovski/mini.notify", -- notifications ui
    event = "VeryLazy",
    opts = true,
  },
  {
    "echasnovski/mini.completion", -- like cmp but fast as fucking fuck (and 0 config)
    enable = true,
    event = "VeryLazy",
    opts = {
      window = {
        info = { border = "rounded" },
        signature = { border = "rounded" },
      },
    },
  },
  {
    "echasnovski/mini.pick", -- a mini telescope but I use it to wrap vim.ui.select
    event = "VeryLazy",
    config = function()
      local minipick = require "mini.pick"
      minipick.setup()
      vim.ui.select = minipick.ui_select
    end,
  },
  {
    enabled = false,
    "echasnovski/mini.statusline", -- statusline
    lazy = false,
    config = function()
      local mini_statusline = require "mini.statusline"
      mini_statusline.setup {
        content = {
          active = function()
            local mode, mode_hl = mini_statusline.section_mode { trunc_width = 120 }
            local filename = mini_statusline.section_filename { trunc_width = 140 }
            local fileinfo = mini_statusline.section_fileinfo {
              trunc_width = 300,--[[ large value to always truncate ]]
            }
            local search = mini_statusline.section_searchcount { trunc_width = 75 }

            return mini_statusline.combine_groups {
              { hl = mode_hl, strings = { mode } },
              "%<", -- Mark general truncate point
              shared.create_statusline_separator(mode_hl, "MiniStatuslineFilename", ""),
              { hl = "MiniStatuslineFilename", strings = { filename } },
              "%=", -- End left alignment
              shared.create_statusline_separator("MiniStatuslineFilename", "MiniStatuslineModeOther", ""),
              { hl = "MiniStatuslineModeOther", strings = { shared.get_lsp_clients_string() } },
              shared.create_statusline_separator("MiniStatuslineModeOther", "MiniStatuslineFileinfo", ""),
              { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
              { hl = mode_hl, strings = { search } },
            }
          end,
        },
      }
    end,
  },
  {
    "echasnovski/mini.starter", -- starter screen
    event = "VimEnter",
    config = function()
      local starter = require "mini.starter"
      starter.setup {
        items = {
          starter.sections.builtin_actions(),
          starter.sections.recent_files(5, true, false),
        },
        content_hooks = {
          -- bullet
          starter.gen_hook.adding_bullet "◦ ",
          -- file name
          starter.gen_hook.aligning("center", "center"),
        },
        footer = "", -- to hide instructions
        query_updaters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.",
      }
    end,
  },
  {
    "echasnovski/mini.map", -- minimap
    init = function()
      require("core.mappings").minimap()
    end,
    config = function()
      local minimap = require "mini.map"
      minimap.setup {
        integrations = {
          -- minimap.gen_integration.gitsigns(),
          minimap.gen_integration.diagnostic(),
          minimap.gen_integration.builtin_search(),
          minimap.gen_integration.diff(),
        },
        window = {
          show_integration_count = false,
        },
      }
    end,
  },
  {
    "echasnovski/mini.files", -- file tree
    init = function()
      require("core.mappings").minifiles()
    end,
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
  {
    "echasnovski/mini-git", -- git client
    cmd = "Git",
    init = function()
      require("core.mappings").minigit()
    end,
    config = function()
      require("mini.git").setup()
    end,
  },
  {
    "echasnovski/mini.diff", -- like git signs but mini
    event = "VeryLazy",
    init = function()
      require("core.mappings").minidiff()
    end,
    config = function()
      require("mini.diff").setup {
        mappings = {
          -- Apply hunks inside a visual/operator region
          apply = "gh",
          -- Reset hunks inside a visual/operator region
          reset = "gH",
          -- Hunk range textobject to be used inside operator
          textobject = "gh",
          -- Go to hunk range in corresponding direction
          goto_first = "[G",
          goto_prev = "[g",
          goto_next = "]g",
          goto_last = "]G",
        },
      }
    end,
  },
  {
    "echasnovski/mini.hues", -- colorizer
    lazy = false,
    priority = 1000,
    config = function()
      require("mini.hues").setup { background = "#202131", foreground = "#c5c6cd" }
    end,
  },
}
