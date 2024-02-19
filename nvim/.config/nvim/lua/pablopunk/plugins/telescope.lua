return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim", -- It sets vim.ui.select to telescope
    },
    keys = {
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files()
        end,
        desc = "Find files",
      },
      {
        "<leader>ff",
        mode = "v",
        [["9y:lua require('telescope.builtin').find_files{search_file=vim.fn.getreg('9')}<cr>]],
        desc = "Find file from visual selection",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").git_status()
        end,
        desc = "Find modified files (git)",
      },
      {
        "<leader>fr",
        function()
          require("telescope.builtin").oldfiles()
        end,
        desc = "Find recent files",
      },
      {
        "<leader>fq",
        function()
          require("telescope.builtin").quickfix()
        end,
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Find buffers",
      },
      {
        "<leader>fs",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Find string",
      },
      {
        "<leader>fw",
        function()
          require("telescope.builtin").grep_string()
        end,
        desc = "Find word under cursor",
      },
      {
        "<leader>fW",
        function()
          require("telescope.builtin").grep_string { search = vim.fn.expand "<cWORD>" }
        end,
        desc = "Find Word under cursor",
      },
      {
        "<leader>fw",
        mode = "v",
        [["9y:lua require('telescope.builtin').grep_string{search=vim.fn.getreg('9')}<cr>]],
        desc = "Find selected string",
      },
      {
        "<leader>fd",
        function()
          require("telescope.builtin").diagnostics()
        end,
        desc = "Find diagnostics",
      },
      {
        "<leader>p",
        function()
          require("telescope.builtin").registers()
        end,
        desc = "List yank registers",
      },
      {
        "<leader><leader>",
        function()
          require("telescope.builtin").keymaps()
        end,
        desc = "Command palette (kinda)",
      },
      {
        "<leader>mm",
        function()
          require("telescope.builtin").marks()
        end,
        desc = "Show marks",
      },
    },
    config = function()
      local telescope = require "telescope"
      local actions = require "telescope.actions"

      telescope.setup {
        defaults = {
          path_display = { "truncate" }, -- if it doesn't fit, show the end (.../foo/bar.js)
          layout_strategy = "vertical",
          selection_caret = "◦ ",
          prompt_prefix = " → ",
          mappings = {
            i = {
              ["<c-k>"] = actions.cycle_history_prev,
              ["<c-j>"] = actions.cycle_history_next,
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
          grep_string = {
            additional_args = function()
              return { "--hidden" }
            end,
          },
          live_grep = {
            additional_args = function()
              return { "--hidden" }
            end,
          },
        },
      }

      telescope.load_extension "fzf"
      telescope.load_extension "ui-select"
    end,
  },
}
