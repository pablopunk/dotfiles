return {
  os = "macos",
  check = "[ -d '/Applications/Tailscale.app' ]",
  install = {
    brew = "brew install homebrew/cask/tailscale",
  },
}
