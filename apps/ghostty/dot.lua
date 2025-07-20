return {
  check = "[[ ghostty || -d '/Applications/Ghostty.app' ]]",
  install = {
    dnf = [[
      sudo dnf copr enable pgdev/ghostty
      sudo dnf install -y ghostty
    ]],
    apt = [[
      curl -s https://packagecloud.io/install/repositories/alvarobp/ubuntu/script.deb.sh | sudo bash
      sudo apt-get install -y ghostty
    ]],
    brew = "brew install ghostty",
  },
  link = {
    ["./config"] = "~/.config/ghostty/config",
  },
}
