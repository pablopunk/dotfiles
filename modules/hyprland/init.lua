return {
  os = { "linux" },
  config = {{
    source= "./hyprland.conf",
    output= "~/.config/hypr/hyprland.conf",
  },
  {
    source= "./hyprland.sh",
    output= "~/.zshrc.d/hyprland.sh",
  }
  }
}
