return {
  os = { "linux" },
  check = "which hyprctl && which ulauncher && which waybar && which copyq",
  install = {
    dnf = "sudo dnf install -y hyprland ulauncher waybar copyq",
  },
  link = {
    ["./hypr"] = "~/.config/hypr",
    ["./ulauncher"] = "~/.config/ulauncher",
  },
}
