return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>d", ":TroubleToggle<cr>", desc = "Toggle trouble for file diagnostics", mode = { "n", "v" } },
    {
      "<leader>D",
      ":TroubleToggle workspace_diagnostics<cr>",
      desc = "Toggle trouble for workspace diagnostics",
      mode = { "n", "v" },
    },
  },
  opts = {},
}
