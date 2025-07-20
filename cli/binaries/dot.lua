return {
  check = "which fzf",
  install = {
    brew = "brew install fzf",
    dnf = "sudo dnf install fzf",
    apt = "sudo apt install fzf",
  },
  link = {
    ["./bin"] = "~/.bin",
  },
}
