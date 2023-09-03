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
      }

      local keymap = vim.keymap
      local opts = { noremap = true, silent = true }
      opts.desc = "Find files"
      keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", opts)
      opts.desc = "Find modified files in git"
      keymap.set("n", "<leader>fg", "<cmd>Telescope git_status<cr>", opts)
      opts.desc = "Find recent files"
      keymap.set("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>", opts)
      opts.desc = "Search string"
      keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", opts)
      opts.desc = "Search word under cursor"
      keymap.set("n", "<leader>fw", "<cmd>Telescope grep_string<cr>", opts)
      opts.desc = "Search selected string"
      keymap.set(
        "v",
        "<leader>fw",
        [["9y:lua require('telescope.builtin').grep_string{search=vim.fn.getreg('9')}<cr>]],
        opts
      )
      opts.desc = "Find diagnostics"
      keymap.set("n", "<leader>fd", "<cmd>lua require('telescope.builtin').diagnostics()<cr>", opts)
      opts.desc = "Open buffers"
      keymap.set("n", "<leader><leader>", "<cmd>Telescope buffers<cr>", opts)
      opts.desc = "Open registers"
      keymap.set("n", "<leader>p", "<cmd>lua require('telescope.builtin').registers()<cr>", opts)

      telescope.load_extension "fzf"
    end,
  },
}
