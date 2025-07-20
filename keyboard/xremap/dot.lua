return {
  os = { "linux" },
  check = "which xremap",
  install = {
    cargo = "cargo install xremap",
  },
  postinstall = [[
    sudo gpasswd -a "$USER" input
    echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/99-input.rules >/dev/null
    echo uinput | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
    sudo modprobe uinput
    sudo udevadm control --reload-rules
    sudo udevadm trigger
  ]],
  link = {
    ["config.yaml"] = "~/.config/xremap/config.yaml",
  },
}
