return {
  brew = {
    "koekeishiya/formulae/yabai",
  },
  config = {
    source = "./yabairc",
    output = "~/.config/yabai/yabairc",
  },
  post_install = "yabai --start-service",
}
