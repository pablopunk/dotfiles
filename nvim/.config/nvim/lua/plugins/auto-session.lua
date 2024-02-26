return {
  {
    lazy = false,
    "rmagatti/auto-session", -- auto save and restore sessions
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("auto-session").setup {
        session_lens = {
          load_on_setup = false, -- don't load session-lens at first (I only use it on telescope)
        },
        log_level = "error",
        auto_session_suppress_dirs = { "/", "~/", "~/src", "~/Downloads", "~/Desktop" },
      }
      require("core.mappings").auto_session()
    end,
  },
}
