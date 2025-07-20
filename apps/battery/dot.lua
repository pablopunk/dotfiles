return {
  os = { "macos" },
  check = "which battery",
  install = {
    brew = "brew install battery",
  },
  postinstall = "battery charge 80 && open /Applications/Battery.app",
}
