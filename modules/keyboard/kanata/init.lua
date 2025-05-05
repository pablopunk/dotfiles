return {
  os = { "linux" },
  brew = {
    "kanata",
  },
  config = {
    {
      source = "./kanata.conf",
      output = "~/.config/kanata/kanata.conf",
    },
    {
      source = "./kanata.service",
      output = "~/.config/kanata/kanata.service",
    },
  },
  post_install = [[
sudo cp ~/.config/kanata/kanata.service /etc/systemd/system/kanata.service
sudo systemctl daemon-reload
sudo systemctl enable --now kanata
]],
}
