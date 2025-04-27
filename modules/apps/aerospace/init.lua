return {
  os = { "mac" },
  brew = {
    "nikitabobko/tap/aerospace",
  },
  config = {
    {
      source = "./aerospace.toml",
      output = "~/.aerospace.toml",
    },
  }
}
