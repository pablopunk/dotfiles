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
      local opts = { noremap = true, silent = true }

      -- Files
      opts.desc = "Find files"
      keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", opts)
      opts.desc = "Find modified files in git"
      keymap.set("n", "<leader>fg", "<cmd>Telescope git_status<cr>", opts)
      opts.desc = "Find recent files"
      keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", opts)
      opts.desc = "Open buffers"
      keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", opts)

      -- Search
      opts.desc = "Search string"
      keymap.set("n", "<leader>ss", "<cmd>Telescope live_grep<cr>", opts)
      opts.desc = "Search word under cursor"
      keymap.set("n", "<leader>sw", "<cmd>Telescope grep_string<cr>", opts)
      opts.desc = "Search selected string"
      keymap.set(
        "v",
        "<leader>fw",
        [["9y:lua require('telescope.builtin').grep_string{search=vim.fn.getreg('9')}<cr>]],
        opts
      )

      -- Diagnostics
      opts.desc = "Find diagnostics"
      keymap.set("n", "<leader>dd", "<cmd>lua require('telescope.builtin').diagnostics()<cr>", opts)
      opts.desc = "Open registers"
      keymap.set("n", "<leader>p", "<cmd>lua require('telescope.builtin').registers()<cr>", opts)

      -- LSP (go-to)
      opts.desc = "Go to definition"
      keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts)
      opts.desc = "Go to references"
      keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)

      -- Opening keymaps looks like a command palette (can search for descriptions)
      opts.desc = "Command palette (kinda)"
      keymap.set("n", "<leader><leader>", "<cmd>Telescope keymaps<cr>", opts)

      telescope.load_extension "fzf"
    end,
  },
}
