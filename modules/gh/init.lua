return {
  brew = { "gh" },
  config = {
    source = "./config.yml",
    output = "~/.config/gh/config.yml",
  },
  post_install = "gh extension install github/gh-copilot --force",
}
