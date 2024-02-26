return {
  {
    enabled = true,
    "zbirenbaum/copilot.lua",
    event = "VeryLazy",
    build = function()
      vim.cmd ":Copilot auth signin"
    end,
    config = function()
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

      require("core.mappings").copilot()
    end,
  },
}
