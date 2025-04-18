return {
  os = { "macos" },
  brew = {
    "karabiner-elements",
  },
  config = {
    source = "./karabiner.json",
    output = "~/.config/karabiner/karabiner.json",
  },
  post_install = "defaults write -g ApplePressAndHoldEnabled -bool false"
}
