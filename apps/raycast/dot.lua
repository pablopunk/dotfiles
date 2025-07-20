return {
  os = { "macos" },
  check = "[ -d '/Applications/Raycast.app' ]",
  install = {
    brew = "brew install raycast",
  },
}
