return {
  check = "which fzf",
  install = {
    dnf = "sudo dnf install -y fzf",
    apt = "sudo apt install -y fzf",
    brew = "brew install fzf",
  },
  link = {
    ["./bin"] = "~/.bin",
  },
}
