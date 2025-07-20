return {
  check = "which nvim && which rg && which stylua",
  install = {
    brew = "brew install neovim ripgrep stylua",
    apt = [[
      curl https://sh.rustup.rs -sSf | sh
      source $HOME/.cargo/env
      cargo install stylua
      sudo apt install -y neovim ripgrep
    ]],
    dnf = [[
      curl https://sh.rustup.rs -sSf | sh
      source $HOME/.cargo/env
      cargo install stylua
      sudo dnf install -y neovim ripgrep
    ]],
  },
  link = {
    ["./neovim.lua"] = "~/.config/nvim/init.lua",
    ["./vscode.lua"] = "~/.config/nvim-vscode/init.lua",
  },
  postinstall = "nvim --headless +qa > /dev/null 2>&1", -- install plugins
}
