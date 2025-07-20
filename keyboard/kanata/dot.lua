return {
  os = { "linux" },
  check = "which kanata",
  install = {
    brew = "brew install kanata",
    cargo = "cargo install kanata",
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
