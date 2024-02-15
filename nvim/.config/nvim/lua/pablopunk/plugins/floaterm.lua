return {
  "voldikss/vim-floaterm",
  keys = {
    {
      "<leader>tt",
      ":FloatermToggle<cr>",
      desc = "Toggle floating terminal",
      mode = { "n", "v" },
    },
    {
      "<leader>tt",
      "<C-\\><C-n>:FloatermToggle<cr>",
      desc = "Toggle floating terminal",
      mode = { "t" },
    },
    {
      "<leader>tn",
      ":FloatermNew<cr>",
      desc = "New floating terminal",
      mode = { "n", "v" },
    },
    {
      "<leader>tn",
      "<C-\\><C-n>:FloatermNew<cr>",
      desc = "New floating terminal",
      mode = { "t" },
    },
    {
      "<leader>tr",
      "<C-\\><C-n>:FloatermPrev<cr>",
      desc = "Previous floating terminal",
      mode = { "t" },
    },
    {
      "<leader>ty",
      "<C-\\><C-n>:FloatermNext<cr>",
      desc = "Next floating terminal",
      mode = { "t" },
    },
  },
}
