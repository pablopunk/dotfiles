return {
  "ap/vim-buftabline", -- show buffers as tabs
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require "alpha"
      local dashboard = require "alpha.themes.dashboard"

      -- Set header
      dashboard.section.header.val = {
        [[                               __                ]],
        [[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
        [[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
        [[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
        [[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
        [[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
        [[                                                 ]],
        [[                                       @pablopunk]],
      }

      -- Set menu
      dashboard.section.buttons.val = {
        dashboard.button("e", " New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("r", " Recent", ":Telescope oldfiles<CR>"),
      }
      alpha.setup(dashboard.opts)
    end,
  },
  {
    "szw/vim-maximizer", -- maximize the current buffer (toggle)
    config = function()
      vim.keymap.set("n", "<leader>m", ":MaximizerToggle<cr>", { silent = true })
    end,
  },
  "markonm/traces.vim", -- to show in real time what your :s commands will replace
  {
    "nvim-tree/nvim-tree.lua", -- file browser
    config = function()
      vim.keymap.set("n", "<c-t>", ":NvimTreeToggle<cr>", { silent = true })
      vim.keymap.set("n", "<c-y>", ":NvimTreeFindFile<cr>", { silent = true })

      local nvimtree = require "nvim-tree"

      -- recommended settings from nvim-tree docs
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.opt.termguicolors = true

      -- fix for lazy-loading nvim-tree
      -- local function open_nvim_tree(data)
      --   local is_git_commit = string.match(data.file, ".git/COMMIT_EDITMSG")
      --   local is_git_merge = string.match(data.file, ".git/MERGE_MSG")
      --   if is_git_commit or is_git_merge then
      --     return
      --   end

      --   local is_a_directory = vim.fn.isdirectory(data.file) == 1

      --   if is_a_directory then
      --     vim.cmd.cd(data.file) -- change directory to the directory of the file
      --     require("nvim-tree.api").tree.open()
      --     return
      --   end

      --   local is_real_file = vim.fn.filereadable(data.file) == 1
      --   local is_no_name_file = data.file == "" and vim.bo[data.buf].buftype == ""

      --   if is_real_file or is_no_name_file then
      --     require("nvim-tree.api").tree.toggle { focus = false, find_file = true }
      --     return
      --   end
      -- end

      -- vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree }) -- open nvim on startup

      nvimtree.setup {
        -- reload_on_bufenter = true,
        update_focused_file = {
          enable = true,
        },
        view = {
          width = 24,
        },
        renderer = {
          indent_width = 1,
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
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = { "BufReadPre", "BufNewFile" },
    config = true,
  },
}
