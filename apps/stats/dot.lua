return {
  os = { "macos" },
  check = "[ -d '/Applications/Stats.app' ]",
  install = {
    brew = "brew install stats",
  },
  defaults = {
    ["eu.exelban.Stats"] = "./Stats.xml",
  },
  postinstall = [[
    open /Applications/Stats.app
  ]],
}
