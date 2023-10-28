return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require "telescope"
      local builtin = require "telescope.builtin"
      local actions = require "telescope.actions"

      telescope.setup {
        defaults = {
          path_display = { "truncate" }, -- if it doesn't fit, show the end (.../foo/bar.js)
          layout_strategy = "vertical",
          mappings = {
            i = {
              ["<c-k>"] = actions.move_selection_previous,
              ["<c-j>"] = actions.move_selection_next,
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
      }

      local keymap = vim.keymap
      local function opts(desc)
        return { noremap = true, silent = true, desc = desc }
      end

      local find_prefix = "<leader>f"

      -- Files
      keymap.set("n", find_prefix .. "f", "<cmd>Telescope find_files<cr>", opts "Find files")
      keymap.set("n", find_prefix .. "g", "<cmd>Telescope git_status<cr>", opts "Find modified files in git")
      keymap.set("n", find_prefix .. "r", "<cmd>Telescope oldfiles<cr>", opts "Find recent files")
      keymap.set("n", find_prefix .. "b", "<cmd>Telescope buffers<cr>", opts "Open buffers")

      -- Search
      keymap.set("n", find_prefix .. "s", "<cmd>Telescope live_grep<cr>", opts "Find string")
      keymap.set("n", find_prefix .. "w", "<cmd>Telescope grep_string<cr>", opts "Find word under cursor")
      keymap.set(
        "v",
        find_prefix .. "w",
        [["9y:lua require('telescope.builtin').grep_string{search=vim.fn.getreg('9')}<cr>]],
        opts "Find selected string"
      )

      -- Diagnostics
      keymap.set("n", find_prefix .. "d", builtin.diagnostics, opts "Find diagnostics")

      -- Yank registers
      keymap.set("n", "<leader>p", builtin.registers, opts "Yank registers")

      -- Opening keymaps looks like a command palette (can search for descriptions)
      keymap.set({ "n", "v" }, "<leader><leader>", "<cmd>Telescope keymaps<cr>", opts "Command palette (kinda)")

      telescope.load_extension "fzf"
    end,
  },
}
