return {
  {
    enabled = false,
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    init = function()
      require("core.mappings").hardtime()
    end,
    lazy = false,
    opts = {
      disable_mouse = false,
      max_count = 5, -- Maximum count of repeated key presses allowed within the max_time period.
      disabled_keys = { -- Disable arrow keys in normal mode but not in insert mode
        ["<Up>"] = { "", "n" },
        ["<Down>"] = { "", "n" },
        ["<Left>"] = { "", "n" },
        ["<Right>"] = { "", "n" },
      },
    },
  },
}
