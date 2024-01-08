return {
  "jackMort/ChatGPT.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  event = "VeryLazy",
  config = function()
    require("chatgpt").setup {
      api_key_cmd = "echo -n $OPENAI_API_KEY",
      edit_with_instructions = {
        keymaps = {
          close = "<C-c>",
          accept = "<C-y>",
          toggle_diff = "<C-d>",
          toggle_settings = "<C-o>",
          toggle_help = "<C-h>",
          cycle_windows = "<Tab>",
          use_output_as_input = "<C-i>",
        },
      },
      popup_input = {
        submit = "<CR>",
      },
    }
    vim.keymap.set("n", "<leader>cg", ":ChatGPT<cr>", { silent = true, noremap = true, desc = "Edit with ChatGPT" })
    vim.keymap.set(
      "v",
      "<leader>cg",
      ":ChatGPTEditWithInstructions<cr>",
      { silent = true, noremap = true, desc = "ChatGPT" }
    )
  end,
}
