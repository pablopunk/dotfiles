return {
  "jackMort/ChatGPT.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
  },
  cmd = {
    "ChatGPT",
    "ChatGPTRun",
    "ChatGPTActAs",
    "ChatGPTCompleteCode",
    "ChatGPTEditWithInstructions",
  },
  keys = {
    {
      "<leader>cg",
      function()
        require("chatgpt").openChat()
      end,
      desc = "ChatGPT",
    },
    {
      mode = "v",
      "<leader>cg",
      function()
        require("chatgpt").edit_with_instructions()
      end,
      desc = "Edit with ChatGPT",
    },
  },
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
      openai_params = {
        model = "gpt-4-turbo-preview",
        frequency_penalty = 0,
        presence_penalty = 0,
        max_tokens = 300,
        temperature = 0,
        top_p = 1,
        n = 1,
      },
      openai_edit_params = {
        model = "gpt-4-turbo-preview",
        frequency_penalty = 0,
        presence_penalty = 0,
        temperature = 0,
        top_p = 1,
        n = 1,
      },
      popup_input = {
        submit = "<CR>",
      },
    }
  end,
}
