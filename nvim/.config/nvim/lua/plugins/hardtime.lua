return {
  {
    enabled = true,
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    init = function()
      require("core.mappings").hardtime()
    end,
    lazy = false,
    opts = {
      disable_mouse = false,
    },
  },
}
