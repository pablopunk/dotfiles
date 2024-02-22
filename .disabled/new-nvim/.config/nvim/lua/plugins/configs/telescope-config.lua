local actions = require "telescope.actions"

local M = {
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

return M
