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
      api_key_cmd = 'op read "op://Personal/OpenAI API Key/api key" --no-newline',
    }
  end,
}
