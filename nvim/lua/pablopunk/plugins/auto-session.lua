return {
  {
    "rmagatti/session-lens", -- session managing through telescope
    dependencies = { "rmagatti/auto-session", "nvim-telescope/telescope.nvim" },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("auto-session").setup {
        log_level = "error",
        cwd_change_handling = {
          post_cwd_changed_hook = function()
            require("lualine").refresh() -- refresh lualine so the new session name is displayed in the status bar
          end,
        },
      }
      require("session-lens").setup {
        path_display = { "shorten" },
      }
      require("telescope").load_extension "session-lens"

      local function opts(desc)
        return { noremap = true, silent = true, desc = desc }
      end
      vim.keymap.set("n", "<leader>ss", "<cmd>Autosession search<cr>", opts "List sessions")
      vim.keymap.set("n", "<leader>sd", "<cmd>Autosession delete<cr>", opts "Delete session")
    end,
  },
}