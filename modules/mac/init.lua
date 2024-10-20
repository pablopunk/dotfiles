return {
  -- Enable when supported.
  -- os = { "mac" },
  brew = {
    "coreutils",
    "battery",
    "nikitabobko/tap/aerospace",
  },
  post_install = "battery charge 80",
  config = {
    {
      source = "./aerospace.toml",
      output = "~/.aerospace.toml",
    },
  },
}
