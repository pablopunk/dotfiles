local t_setup, t = pcall(require, "telescope")
if not t_setup then
  return
end

local a_setup, a = pcall(require, "telescope.actions")
if not a_setup then
  return
end

t.setup({
  defaults = {
    mappings = {
      i = {
        ["<c-k>"] = a.move_selection_previous,
        ["<c-j>"] = a.move_selection_next,
        -- ["<c-q>"] = a.send_selected_to_qflist + a.open_qflist,
      }
    }
  }
})

t.load_extension("fzf")
