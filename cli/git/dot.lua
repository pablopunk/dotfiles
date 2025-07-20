return {
  check = "which git && which delta && which gh",
  install = {
    brew = "brew install git git-delta gh",
    dnf = [[
      sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      sudo dnf install gh git-delta git
    ]],
    apt = [[
      (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
      && sudo mkdir -p -m 755 /etc/apt/keyrings \
      && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
      && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
      && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
      && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
      && sudo apt update \
      && sudo apt install gh git-delta git -y
    ]],
  },
  link = {
    ["./gitconfig"] = "~/.gitconfig",
    ["./gh.yml"] = "~/.config/gh/config.yml",
  },
  postinstall = [[
    gh auth status | grep 'Logged in to github.com account' > /dev/null || gh auth login --web -h github.com
    gh extension list | grep gh-copilot > /dev/null || gh extension install github/gh-copilot
  ]],
}
