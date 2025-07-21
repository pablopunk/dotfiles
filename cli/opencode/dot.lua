return {
  check = "which opencode",
  install = {
    brew = "brew install sst/tap/opencode",
    curl = "VERSION=latest curl -fsSL https://opencode.ai/install | bash",
  },
  link = {
    ["./opencode.json"] = "~/.config/opencode/opencode.json",
  },
}
