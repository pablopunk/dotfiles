return {
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.0",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-live-grep-args.nvim" },
    config = function()
      local t_setup, t = pcall(require, "telescope")
      if not t_setup then
        return
      end

      local a_setup, a = pcall(require, "telescope.actions")
      if not a_setup then
        return
      end

      t.setup {
        defaults = {
          path_display = { "truncate" }, -- if it doesn't fit, show the end (.../foo/bar.js)
          layout_strategy = "vertical",
          mappings = {
            i = {
              ["<c-k>"] = a.move_selection_previous,
              ["<c-j>"] = a.move_selection_next,
              -- ["<c-q>"] = a.send_selected_to_qflist + a.open_qflist,
            },
          },
        },
      }

      local opts = { noremap = true, silent = true }
      local keymap = vim.keymap
      keymap.set("n", "<c-p>", "<cmd>Telescope find_files<cr>")
      keymap.set("n", "<c-g>", "<cmd>Telescope git_status<cr>")
      keymap.set("n", "<c-f>", "<cmd>Telescope live_grep<cr>")
      keymap.set("n", "<leader>fw", "<cmd>Telescope grep_string<cr>")
      keymap.set("v", "<leader>fw", [["9y:lua require('telescope.builtin').grep_string{search=vim.fn.getreg('9')}<cr>]])
      keymap.set("n", "<leader>fd", "<cmd>lua require('telescope.builtin').diagnostics()<cr>", opts)
      keymap.set("n", "<leader><leader>", "<cmd>Telescope buffers<cr>")
      keymap.set("n", "<leader>p", "<cmd>lua require('telescope.builtin').registers()<cr>")
      keymap.set("n", "<leader>o", "<cmd>Telescope old_files<cr>", opts)

      t.load_extension "fzf"
    end,
  },
}
