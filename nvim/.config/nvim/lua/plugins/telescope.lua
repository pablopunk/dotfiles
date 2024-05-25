return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
        config = function()
          require("telescope").load_extension "fzf"
        end,
      },
      {
        "camgraff/telescope-tmux.nvim", -- tmux sessions in telescope
        config = function()
          require("telescope").load_extension "tmux"
        end,
      },
    },
    init = function()
      require("core.mappings").telescope()
    end,
    config = function()
      local telescope = require "telescope"
      local actions = require "telescope.actions"

      telescope.setup {
        defaults = {
          file_ignore_patterns = { ".git/", "node_modules/", "vendor/" },
          path_display = { "truncate" }, -- if it doesn't fit, show the end (.../foo/bar.js)
          layout_strategy = "vertical",
          selection_caret = "◦ ",
          prompt_prefix = " → ",
          mappings = {
            i = {
              ["<c-k>"] = actions.cycle_history_prev,
              ["<c-j>"] = actions.cycle_history_next,
              ["<c-f>"] = actions.move_selection_previous, -- useful when i use c-f to open telescope
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
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {},
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
    end,
  },
}
