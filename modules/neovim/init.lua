return {
  brew = {
    -- { name = "neovim", options = "--HEAD" },
    "neovim",
    "ripgrep",
    "stylua",
  },
  config = {
    {
      source = "./neovim.lua",
      output = "~/.config/nvim/init.lua",
    },
    {
      source = "./vscode.lua",
      output = "~/.config/nvim-vscode/init.lua",
    },
  },
  post_install = "nvim --headless +qa > /dev/null 2>&1", -- install plugins
}
