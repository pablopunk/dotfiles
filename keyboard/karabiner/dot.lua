return {
  os = { "macos" },
  check = "[ -d /Applications/Karabiner-Elements.app/ ]",
  install = {
    brew = "brew install karabiner-elements",
  },
  link = {
    ["./karabiner.json"] = "~/.config/karabiner/karabiner.json",
  },
  postinstall = "defaults write -g ApplePressAndHoldEnabled -bool false",
}
