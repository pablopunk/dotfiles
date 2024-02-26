return {
  {
    "pablopunk/todo.nvim",
    dev = true, -- use local version if exists
    cmd = "TodoToggle",
    init = function()
      require("core.mappings").todo()
    end,
    config = true,
  },
}
