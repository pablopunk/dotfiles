return {
  check = "[[ ghostty || -d '/Applications/Ghostty.app' ]]",
  install = {
    dnf = [[
      sudo dnf copr enable pgdev/ghostty
      sudo dnf install ghostty
    ]],
    brew = "brew install ghostty",
  },
  link = {
    ["./config"] = "~/.config/ghostty/config",
  },
}
