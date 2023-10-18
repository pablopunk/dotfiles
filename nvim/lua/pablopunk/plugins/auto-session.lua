return {
  {
    "rmagatti/session-lens", -- session managing through telescope
    dependencies = { "rmagatti/auto-session", "nvim-telescope/telescope.nvim" },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("auto-session").setup {
        log_level = "error",
      }
      require("session-lens").setup {
        path_display = { "shorten" },
      }
      require("telescope").load_extension "session-lens"

      local function opts(desc)
        return { noremap = true, silent = true, desc = desc }
      end
      vim.keymap.set("n", "<leader>ss", "<cmd>Telescope session-lens<cr>", opts "List sessions")
      vim.keymap.set("n", "<leader>sd", "<cmd>SessionDelete<cr>", opts "Delete session")

      -- restore nvim-tree properly
      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        pattern = "NvimTree*",
        callback = function()
          local api = require "nvim-tree.api"
          local view = require "nvim-tree.view"

          if not view.is_visible() then
            api.tree.open()
          end
        end,
      })
    end,
  },
}
