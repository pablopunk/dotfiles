return {
  brew = {
    "koekeishiya/formulae/skhd",
  },
  config = {
    source = "./skhdrc",
    output = "~/.config/skhd/skhdrc",
  },
  post_install = "skhd --start-service",
}
