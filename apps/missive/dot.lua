return {
  os = { "macos" },
  check = "[ -d '/Applications/Missive.app' ]",
  install = {
    brew = "brew install missive",
  },
}
