return {
  check = "[ -d '/Applications/Ghostty.app' ]",
  install = {
    brew = "brew install ghostty",
  },
  link = {
    ["./config"] = "~/.config/ghostty/config",
  },
}
