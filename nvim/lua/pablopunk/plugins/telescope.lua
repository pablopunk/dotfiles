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
keymap.set("n", "ge", "<cmd>lua require('telescope.builtin').diagnostics()<cr>", opts)
keymap.set("n", "<c-p>", "<cmd>Telescope find_files<cr>")
keymap.set("n", "<c-g>", "<cmd>Telescope git_status<cr>")
keymap.set("n", "<c-f>", "<cmd>Telescope live_grep<cr>")
keymap.set("n", "<leader>f", "<cmd>Telescope grep_string<cr>")
keymap.set("v", "<leader>f", [["9y:lua require('telescope.builtin').grep_string{search=vim.fn.getreg('9')}<cr>]])
-- keymap.set("n", "<leader>g", [[:lua require('telescope.builtin').grep_string{search=''}<cr>]])
keymap.set("n", "<leader><leader>", "<cmd>Telescope buffers<cr>")
keymap.set("n", "<leader>v", "<cmd>lua require('telescope.builtin').registers()<cr>")
keymap.set("n", "<leader>o", "<cmd>lua require('telescope.builtin').jumplist()<cr>")

t.load_extension "fzf"
