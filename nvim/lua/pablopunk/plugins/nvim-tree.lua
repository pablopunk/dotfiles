return {
  {
    "nvim-tree/nvim-tree.lua", -- file browser
    keys = {
      { "<c-t>", ":NvimTreeToggle<cr>", { silent = true, desc = "Open file tree" } },
      { "<c-y>", ":NvimTreeFindFile<cr>", { silent = true, desc = "Find file in tree" } },
    },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local nvimtree = require "nvim-tree"

      -- recommended settings from nvim-tree docs
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.opt.termguicolors = true

      nvimtree.setup {
        sync_root_with_cwd = true,

        update_focused_file = {
          enable = true,
        },
        view = {
          width = 24,
        },
        renderer = {
          indent_width = 1,
          icons = {
            glyphs = {
              folder = {
                default = "",
                open = "",
                symlink = "",
              },
              git = {
                unstaged = "",
                staged = "",
                unmerged = "",
                renamed = "",
                untracked = "",
                deleted = "",
                ignored = "",
              },
            },
          },
        },
        diagnostics = {
          enable = true,
          show_on_dirs = false,
          show_on_open_dirs = true,
          debounce_delay = 50,
          severity = {
            -- :help vim.diagnostic.severity
            min = vim.diagnostic.severity.WARN,
            max = vim.diagnostic.severity.ERROR,
          },
        },
      }
    end,
  },
}
