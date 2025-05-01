return {
  os = { "macos" },
  brew = {
    "nikitabobko/tap/aerospace --cask",
  },
  config = {
    source = "./aerospace.toml",
    output = "~/.aerospace.toml",
  },
}
