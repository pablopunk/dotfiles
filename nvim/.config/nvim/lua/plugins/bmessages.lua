return {
  {
    "ariel-frischer/bmessages.nvim",
    cmd = "Bmessages",
    init = function()
      require("core.mappings").bmessages()
    end,
    config = true,
  },
}
