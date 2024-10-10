return {
  brew = { "cursor" },
  config = {
    {
      source = "./config/settings.json",
      output = "~/Library/Application Support/Cursor/User/settings.json",
    },
    {
      source = "./config/keybindings.json",
      output = "~/Library/Application Support/Cursor/User/keybindings.json",
    },
    {
      source = "./config/extensions.json",
      output = "~/.cursor/extensions/extensions.json",
    },
  },
}
