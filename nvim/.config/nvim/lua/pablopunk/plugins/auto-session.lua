return {
  {
    "rmagatti/auto-session", -- auto save and restore sessions
    config = function()
      require("auto-session").setup {
        session_lens = {
          load_on_setup = false, -- don't load session-lens at first (I only use it on telescope)
        },
        log_level = "error",
        auto_session_suppress_dirs = { "/", "~/", "~/src", "~/Downloads", "~/Desktop" },
      }
      vim.keymap.set("n", "<leader>sd", function()
        vim.cmd "silent! SessionDelete" -- delete session
        vim.cmd "silent! %bd" -- close all buffers
        local ok, starter = pcall(require, "mini.starter")
        if ok then
          starter.open()
        end
      end, { desc = "Delete session", noremap = true, silent = true })
    end,
  },
  {
    "rmagatti/session-lens", -- session managing through telescope
    requires = { "nvim-telescope/telescope.nvim" },
    keys = {
      {
        "<leader>ss",
        function()
          require("telescope").extensions["session-lens"].search_session()
        end,
      },
    },
    config = function()
      require("session-lens").setup {
        path_display = { "shorten" },
      }
      require("telescope").load_extension "session-lens"
    end,
  },
}
