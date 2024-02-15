return {
  {
    "pablopunk/todo.nvim",
    dev = true, -- use local version if exists
    cmd = "TodoToggle",
    keys = {
      {
        "<leader>td",
        function()
          require("todo").toggle_todo_window()
        end,
        desc = "Toggle todo.nvim window",
      },
    },
  },
}
