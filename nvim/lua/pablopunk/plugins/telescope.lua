return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.0",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require "telescope"
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

      -- Files
      keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", opts "Find files")
      keymap.set("n", "<leader>fg", "<cmd>Telescope git_status<cr>", opts "Find modified files in git")
      keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", opts "Find recent files")
      keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", opts "Open buffers")

      -- Search
      keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", opts "Find string")
      keymap.set("n", "<leader>fw", "<cmd>Telescope grep_string<cr>", opts "Find word under cursor")
      keymap.set(
        "v",
        "<leader>fw",
        [["9y:lua require('telescope.builtin').grep_string{search=vim.fn.getreg('9')}<cr>]],
        opts "Search selected string"
      )

      -- Diagnostics
      keymap.set("n", "<leader>fd", "<cmd>lua require('telescope.builtin').diagnostics()<cr>", opts "Find diagnostics")
      keymap.set("n", "<leader>p", "<cmd>lua require('telescope.builtin').registers()<cr>", opts "Open registers")

      -- LSP (go-to)
      keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts "Go to definition")
      keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts "Go to references")

      -- Opening keymaps looks like a command palette (can search for descriptions)
      keymap.set({ "n", "v" }, "<leader><leader>", "<cmd>Telescope keymaps<cr>", opts "Command palette (kinda)")

      telescope.load_extension "fzf"
    end,
  },
}
