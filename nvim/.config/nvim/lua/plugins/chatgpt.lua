return {
  {
    "Robitx/gp.nvim",
    cmd = {
      -- Chat Commands
      "GpChatNew",
      "GpChatPaste",
      "GpChatToggle",
      "GpChatFinder",
      "GpChatRespond",
      "GpChatDelete",
      -- Text/Code Commands
      "GpRewrite",
      "GpAppend",
      "GpPrepend",
      "GpEnew",
      "GpNew",
      "GpVnew",
      "GpTabnew",
      "GpPopup",
      "GpImplement",
      "GpContext",
      "GpAgent",
    },
    init = function()
      require("core.mappings").gp()
    end,
    config = function()
      require("gp").setup {
        agents = {
          {
            name = "CodeGPT4o",
            chat = false,
            command = true,
            model = { model = "gpt-4o", temperature = 0.8, top_p = 1 },
            system_prompt = "You are an AI working as a code editor.\n\n"
              .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
              .. "Please don't use markdown, just plain text.\n\n",
          },
          { name = "ChatGPT4" },
        },
      }
    end,
  },
  {
    enabled = false,
    "jackMort/ChatGPT.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    init = function()
      require("core.mappings").chatgpt()
    end,
    cmd = {
      "ChatGPT",
      "ChatGPTRun",
      "ChatGPTActAs",
      "ChatGPTCompleteCode",
      "ChatGPTEditWithInstructions",
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
        popup_input = { submit = "<CR>" },
      }
    end,
  },
}
