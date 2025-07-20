return {
  os = "linux",
  check = "which waybar",
  install = {
    dnf = "sudo dnf install -y waybar fontawesome-fonts fontawesome-6-free-fonts brightnessctl nm-connection-editor blueman pavucontrol",
  },
  link = {
    ["./config"] = "~/.config/waybar",
  },
}
