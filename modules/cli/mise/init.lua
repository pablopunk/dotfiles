return {
  brew = {
    "mise"
  },
  config = {
    source = "./config.toml",
    output = "~/.config/mise/config.toml",
  },
  post_install = "cd ~/ && mise install ; cd -",
}
