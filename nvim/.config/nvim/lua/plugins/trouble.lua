return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  init = function()
    require("core.keymaps").trouble()
  end,
  opts = {},
}
