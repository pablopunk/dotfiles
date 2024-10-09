return {
  brew = {
    { name = "neovim", options = "--HEAD" },
    "ripgrep"
  },
  config = {
    source = "./config",
    output = "~/.config/nvim",
  }
}