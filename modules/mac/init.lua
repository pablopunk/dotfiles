return {
  -- Enable when supported.
  -- os = { "mac" },
  brew = {
    "coreutils",
    "battery",
    "yabai",
    "skhd",
  },
  post_install = "battery charge 80; yabai --restart-server; skhd restart-server",
  config = {
    {
      source = "./yabairc",
      output = "~/.config/yabai/yabairc",
    },
    {
      source = "./skhdrc",
      output = "~/.config/skhd/skhdrc",
    },
  },
}
