return {
  {
    "zbirenbaum/copilot.lua",
    event = "VeryLazy",
    build = function()
      vim.cmd ":Copilot auth signin"
    end,
    config = function()
      -- workaround for Tab not inserting a tab character https://github.com/zbirenbaum/copilot.lua/discussions/153#discussioncomment-5701223
      vim.keymap.set("i", "<Tab>", function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { desc = "Super Tab. Accept Copilot suggestion or insert a tab character if there's none" })

      -- workaround for Copilot not suggesting multiple times
      -- /opt/homebrew/opt/gnu-sed/libexec/gnubin -zi 's,\(\.stop=\[\)`\n`\],\1`\n\n\n`],' ~/.local/share/nvim/lazy/copilot.lua/copilot/dist/agent.js
      require("copilot").setup {
        panel = {
          enabled = false,
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
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
  -- {
  --   "zbirenbaum/copilot-cmp", -- Turn copilot into a cmp source. Config in ./lsp.lua
  --   dependencies = { "onsails/lspkind.nvim" },
  --   config = function()
  --     require("copilot_cmp").setup()
  --     require("lspkind").init {
  --       symbol_map = {
  --         Copilot = "", -- copilot icon
  --       },
  --     }
  --   end,
  -- },
}