return {
  {
    "pablopunk/todo.nvim",
    dev = true, -- use local version if exists
    cmd = "TodoToggle",
    init = function()
      require("core.keymaps").todo()
    end,
    config = true,
  },
}
