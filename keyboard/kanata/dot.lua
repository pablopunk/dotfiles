return {
  os = { "linux" },
  check = "which kanata",
  install = {
    brew = "brew install kanata",
    apt = [[
      curl https://sh.rustup.rs -sSf | sh
      cargo install kanata
    ]],
    dnf = [[
      curl https://sh.rustup.rs -sSf | sh
      cargo install kanata
    ]],
  },
  link = {
    ["./kanata.conf"] = "~/.config/kanata/kanata.conf",
    ["./kanata.service"] = "~/.config/kanata/kanata.service",
  },
  postinstall = [[
    sudo cp ~/.config/kanata/kanata.service /etc/systemd/system/kanata.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now kanata
  ]],
}
