return {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
      -- workaround for Tab not inserting a tab character https://github.com/zbirenbaum/copilot.lua/discussions/153#discussioncomment-5701223
      -- vim.keymap.set("i", "<Tab>", function()
      --   if require("copilot.suggestion").is_visible() then
      --     require("copilot.suggestion").accept()
      --   else
      --     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
      --   end
      -- end, { desc = "Super Tab. Accept Copilot suggestion or insert a tab character if there's none" })
      --
      require("copilot").setup {
        panel = {
          enabled = false,
        },
        suggestion = {
          enabled = false, -- disabled to use copilot-cmp instead
          auto_trigger = false, -- disabled to use copilot-cmp instead
        },
        filetypes = {
          yaml = true,
          markdown = true,
          help = true,
          gitcommit = true,
          ["."] = true,
        },
      }
    end,
  },
  {
    "zbirenbaum/copilot-cmp", -- Turn copilot into a cmp source. Config in ./lsp.lua
    dependencies = { "onsails/lspkind.nvim" },
    config = function()
      require("copilot_cmp").setup()
      require("lspkind").init {
        symbol_map = {
          Copilot = "", -- copilot icon
        },
      }
    end,
  },
}
