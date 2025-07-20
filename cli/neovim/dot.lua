return {
  check = "which nvim && which rg && which stylua",
  install = {
    brew = "brew install neovim ripgrep",
    apt = "apt install -y neovim ripgrep",
    dnf = "dnf install -y neovim ripgrep",
  },
  postinstall = [[
    ( which stylua || cargo install stylua || echo "Please install stylua with 'cargo install stylua'" );
    nvim --headless +qa > /dev/null 2>&1
  ]],
  link = {
    ["./neovim.lua"] = "~/.config/nvim/init.lua",
    ["./vscode.lua"] = "~/.config/nvim-vscode/init.lua",
  },
}
