return {
  {
    "echasnovski/mini.comment", -- comments with gcc
    config = true,
    event = "VeryLazy",
  },
  {
    "echasnovski/mini.pairs", -- autopairs for (), {}, [], '', ""...
    config = true,
    event = "VeryLazy",
  },
  {
    "echasnovski/mini.splitjoin", -- `gS` split or join function arguments
    config = true,
    event = "VeryLazy",
  },
  {
    "echasnovski/mini.cursorword", -- highlight word under cursor
    config = true,
    event = "VeryLazy",
  },
  {
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
              trunc_width = 300 --[[ large value to always truncate ]],
            }
            local search = mini_statusline.section_searchcount { trunc_width = 75 }
            local clients = {}
            for _, client in ipairs(vim.lsp.buf_get_clients()) do
              table.insert(clients, client.name)
            end
            local lsp_clients = #clients == 1 and ("↯ " .. clients[1]) or table.concat(clients, " ↯ ")

            return mini_statusline.combine_groups {
              { hl = mode_hl, strings = { mode } },
              "%<", -- Mark general truncate point
              { hl = "MiniStatuslineFilename", strings = { filename } },
              "%=", -- End left alignment
              { hl = "MiniStatuslineModeOther", strings = { lsp_clients } },
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
    lazy = false,
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
      }
    end,
  },
  {
    "echasnovski/mini.files", -- file tree
    init = function()
      if vim.fn.argc(-1) == 1 then
        local stat = vim.loop.fs_stat(vim.fn.argv(0))
        if stat and stat.type == "directory" then
          require "mini.files"
        end
      end
    end,
    keys = {
      {
        "<c-t>",
        mode = { "n", "v" },
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
