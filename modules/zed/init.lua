return {
  brew = {
    "zed",
  },
  config = {
    {
      source = "./keymap.json",
      output = "~/.config/zed/keymap.json",
    },
    {
      source = "./settings.json",
      output = "~/.config/zed/settings.json",
    },
  },
}
