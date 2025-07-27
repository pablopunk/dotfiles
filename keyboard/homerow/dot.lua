return {
  os = { "macos" },
  check = "[ -d /Applications/Homerow.app ]",
  install = {
    brew = "brew install homerow",
  },
}
