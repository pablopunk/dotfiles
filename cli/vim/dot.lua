return {
  check = "which vim && which rg",
  install = {
    brew = "brew install vim ripgrep",
    apt = "sudo apt install -y vim ripgrep",
    dnf = "sudo dnf install -y vim ripgrep",
  },
  link = {
    ["./vimrc"] = "~/.vimrc",
  },
}
