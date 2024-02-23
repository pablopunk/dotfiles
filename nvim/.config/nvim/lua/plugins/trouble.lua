return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "TroubleToggle",
  init = function()
    require("core.keymaps").trouble()
  end,
  opts = {},
}
