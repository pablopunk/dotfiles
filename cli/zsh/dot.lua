return {
  check = "which eza && which fd && which jq && which tldr && which tree && which vim && which wget && which zoxide && which zsh",
  install = {
    apt = "sudo apt install -y eza fd-find jq tldr tree vim wget zoxide zsh",
    dnf = "sudo dnf install -y eza fd-find jq tldr tree vim wget zoxide zsh",
    brew = "brew install eza fd jq tldr tree vim wget zoxide zsh",
  },
  link = {
    ["./zshrc"] = "~/.zshrc",
    ["./zimrc"] = "~/.zimrc",
    ["./zshrc.d/aliases.sh"] = "~/.zshrc.d/aliases.sh",
    ["./zshrc.d/path.sh"] = "~/.zshrc.d/path.sh",
    ["./zshrc.d/functions.sh"] = "~/.zshrc.d/functions.sh",
    ["./zshrc.d/lazy.sh"] = "~/.zshrc.d/lazy.sh",
    -- The temptation to just link the directory
    -- ["./zshrc.d"] = "~/.zshrc.d",
    -- but it's not a good idea because sometimes
    -- I wanna add ONLY LOCALLY files like .secrets.sh
    -- to the .zshrc.d directory, and I don't want to
    -- commit them to the repo.
  },
  postinstall = "curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh",
}
