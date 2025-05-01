return {
  os = { "macos" },
  brew = {
    "FelixKratz/formulae/borders",
  },
  config = {
    source = "./bordersrc",
    output = "~/.config/borders/bordersrc",
  },
  post_install = "brew services restart borders",
}
