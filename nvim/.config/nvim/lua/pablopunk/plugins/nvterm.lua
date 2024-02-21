return {
  "NvChad/nvterm",
  keys = {
    {
      "<leader>tt",
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      desc = "Toggle horizontal terminal",
      mode = { "n", "v" },
    },
    {
      "<leader>tt",
      function()
        vim.cmd [[stopinsert]]
        require("nvterm.terminal").toggle "horizontal"
      end,
      desc = "Toggle horizontal terminal",
      mode = { "t" },
    },
  },
  config = true,
}
