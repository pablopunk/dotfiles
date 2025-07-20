return {
  os = { "macos" },
  check = "[ -d '/Applications/Arc.app' ]",
  install = {
    brew = "brew install arc",
  },
}
