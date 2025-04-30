return {
  brew = {
    "eza",
    "fd",
    "jq",
    -- "python3",
    "tldr",
    "vim",
    "watchman",
    "wget",
    "zoxide",
    "zsh",
  },
  config = {
    {
      source = "./zshrc",
      output = "~/.zshrc",
    },
    {
      source = "./zimrc",
      output = "~/.zimrc",
    },
    {
      source = "./zshrc.d/aliases.sh",
      output = "~/.zshrc.d/aliases.sh",
    },
    {
      source = "./zshrc.d/path.sh",
      output = "~/.zshrc.d/path.sh",
    },
    {
      source = "./zshrc.d/functions.sh",
      output = "~/.zshrc.d/functions.sh",
    },
    {
      source = "./zshrc.d/lazy.sh",
      output = "~/.zshrc.d/lazy.sh",
    },
  },
  post_install = "curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh",
}
