return {
  {
    "pablopunk/unclutter.nvim", -- tabline plugin that helps you focus
    dev = true,
    -- event = "BufWinEnter", -- use this for tabline
    init = function()
      require("core.mappings").unclutter()
    end,
    opts = {
      clean_after = 0,
      tabline = false,
    },
  },
}
