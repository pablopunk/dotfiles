return {
  brew = { "gh" },
  config = {
    source = "./config.yml",
    output = "~/.config/gh/config.yml",
  },
  post_install = [[
    gh auth status | grep 'Logged in to github.com account' > /dev/null || gh auth login --web -h github.com
    gh extension list | grep gh-copilot > /dev/null || gh extension install github/gh-copilot
  ]],
}
