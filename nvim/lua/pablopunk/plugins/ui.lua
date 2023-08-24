return {
  "ap/vim-buftabline", -- show buffers as tabs
  {
    "glepnir/dashboard-nvim",
    event = "VimEnter",
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
    config = function()
      require("dashboard").setup {
        theme = "hyper",
        config = {
          week_header = {
            enable = true,
          },
        },
      }
    end,
  },
  "markonm/traces.vim", -- to show in real time what your :s commands will replace
  {
    "nvim-tree/nvim-tree.lua", -- file browser
    config = function()
      local setup, nvimtree = pcall(require, "nvim-tree")
      if not setup then
        return
      end

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
  "nvim-tree/nvim-web-devicons", -- file browser icons
}
