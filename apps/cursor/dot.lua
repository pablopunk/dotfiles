return {
  os = { "macos" },
  check = "which cursor",
  install = {
    brew = "brew install cursor",
  },
  link = {
    ["./config/settings.json"] = "~/Library/Application Support/Cursor/User/settings.json",
    ["./config/keybindings.json"] = "~/Library/Application Support/Cursor/User/keybindings.json",
    -- ["./config/extensions.json"] = "~/.cursor/extensions/extensions.json",
  },
}
