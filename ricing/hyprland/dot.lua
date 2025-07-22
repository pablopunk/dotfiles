return {
  os = { "linux" },
  check = "which hyprctl && which ulauncher && which waybar && which copyq && which hyprshot",
  install = {
    dnf = "sudo dnf install -y hyprland ulauncher waybar copyq hyprshot",
  },
  link = {
    ["./hypr"] = "~/.config/hypr",
    ["./ulauncher"] = "~/.config/ulauncher",
  },
}
