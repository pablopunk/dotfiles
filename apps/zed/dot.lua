return {
  os = "macos",
  check = "which zed",
  install = {
    brew = "brew install zed",
  },
  link = {
    ["./keymap.json"] = "~/.config/zed/keymap.json",
    ["./settings.json"] = "~/.config/zed/settings.json",
  },
}
