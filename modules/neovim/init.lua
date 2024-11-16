return {
  brew = {
    -- { name = "neovim", options = "--HEAD" },
    "neovim",
    "ripgrep",
  },
  config = {
    source = "./config.lua",
    output = "~/.config/nvim/init.lua",
  },
  post_install = "nvim --headless +qa > /dev/null 2>&1", -- install plugins
}
