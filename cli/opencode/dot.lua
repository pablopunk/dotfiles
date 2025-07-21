return {
  check = "which opencode",
  install = {
    brew = "brew install sst/tap/opencode",
    bun = "bun install -g opencode-ai@latest",
    npm = "npm install -g opencode-ai@latest",
    curl = "VERSION=latest curl -fsSL https://opencode.ai/install | bash",
  },
  link = {
    ["./opencode.json"] = "~/.config/opencode/opencode.json",
  },
}
