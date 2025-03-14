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
      source = "./aliases",
      output = "~/.aliases",
    },
    {
      source = "./path",
      output = "~/.path",
    },
    {
      source = "./functions",
      output = "~/.functions",
    },
    {
      source = "./lazy",
      output = "~/.lazy",
  },
  post_install = "curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh",
}
