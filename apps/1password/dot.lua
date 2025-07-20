return {
  os = { "macos" },
  check = "[ -d '/Applications/1Password.app' ]",
  install = {
    brew = "brew install 1password",
  },
}
