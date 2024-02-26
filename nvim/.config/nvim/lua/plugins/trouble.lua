return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "TroubleToggle",
  init = function()
    require("core.mappings").trouble()
  end,
  opts = {},
}
