return {
  os = { "macos" },
  check = "which aerospace",
  install = {
    brew = "brew install nikitabobko/tap/aerospace --cask",
    -- brew = "FelixKratz/formulae/borders",
  },
  link = {
    ["./aerospace.toml"] = "~/.aerospace.toml",
    ["./bordersrc"] = "~/.config/borders/bordersrc",
  },
  postinstall = [[
    brew services restart borders
  ]],
}
