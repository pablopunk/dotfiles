return {
  brew = {
--     { name = "neovim", options = "--HEAD" },
    "neovim",
    "ripgrep",
  },
  config = {
    source = "./config",
    output = "~/.config/nvim",
  },
}

