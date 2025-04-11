return {
  os = { "macos" },
  brew = {
    "battery",
  },
  post_install = "battery charge 80 && open /Applications/Battery.app",
}
