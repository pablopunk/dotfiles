return {
  {
    "rmagatti/auto-session", -- auto save and restore sessions
    lazy = false,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("auto-session").setup {
        session_lens = {
          load_on_setup = false, -- don't load session-lens at first (I only use it on telescope)
        },
        log_level = "error",
        auto_restore_enabled = false,
        auto_session_suppress_dirs = { "/", "~/", "~/src", "~/Downloads", "~/Desktop" },
        auto_session_use_git_branch = true,
        bypass_session_save_file_types = { "NvimTree", "Lazy", "Starter" },
      }
      require("core.mappings").auto_session()
    end,
  },
}
