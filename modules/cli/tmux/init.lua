return {
  brew = {
    "tmux",
    "bash", -- the homebrew version of bash is necessary for janoamaral/tokyo-night-tmux
  },
  config = {
    source = "./tmux.conf",
    output = "~/.tmux.conf",
  },
  post_install = "[ -d ~/.tmux/plugins ] || mkdir -p ~/.tmux/plugins",
}
