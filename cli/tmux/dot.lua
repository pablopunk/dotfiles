return {
  check = "which tmux",
  install = {
    brew = "brew install tmux bash", -- the homebrew version of bash is necessary for janoamaral/tokyo-night-tmux
    apt = "sudo apt install -y tmux",
    dnf = "sudo dnf install -y tmux",
  },
  link = {
    ["./tmux.conf"] = "~/.tmux.conf",
  },
  postinstall = "[ -d ~/.tmux/plugins ] || mkdir -p ~/.tmux/plugins",
}
