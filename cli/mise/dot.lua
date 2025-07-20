return {
  check = "which mise",
  install = {
    curl = "curl https://mise.run | sh",
  },
  link = {
    ["./config.toml"] = "~/.config/mise/config.toml",
  },
  postinstall = "cd ~/ && mise install ; cd -",
}
