return {
  os = { "macos" },
  check = "which karabiner-elements",
  install = {
    brew = "brew install karabiner-elements",
  },
  link = {
    ["./karabiner.json"] = "~/.config/karabiner/karabiner.json",
  },
  postinstall = "defaults write -g ApplePressAndHoldEnabled -bool false",
}
