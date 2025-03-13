return {
  brew = {
    "eza",
    "fd",
    "jq",
--     "python3",
    "tldr",
    "vim",
    "watchman",
    "wget",
    "zoxide",
    "zsh",
    "zsh-autosuggestions",
    "zsh-syntax-highlighting",
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
      source = "./cargo",
      output = "~/.cargo_zsh",
    },
    {
      source = "./bun",
      output = "~/.bun_zsh",
    },
  },
--   post_install = "curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh"
}
