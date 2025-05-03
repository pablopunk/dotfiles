return {
  os = { "macos" },
  brew = {
    "nikitabobko/tap/aerospace --cask",
    "FelixKratz/formulae/borders",
  },
  config = {
    {
      source = "./aerospace.toml",
      output = "~/.aerospace.toml",
    },
    {
      source = "./bordersrc",
      output = "~/.config/borders/bordersrc",
    },
  },
  post_install = "brew services restart borders",
}
