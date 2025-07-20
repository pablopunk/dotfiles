return {
  link = {
    ["./images"] = "~/.config/wallpapers",
  },
  postinstall = [[
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$HOME/.config/wallpapers/fuji.jpg\""
  ]],
}
