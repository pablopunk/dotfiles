return {
  os = { "macos" },
  check = "[ -d '/Applications/Telegram.app' ]",
  install = {
    brew = "brew install telegram",
  },
}
