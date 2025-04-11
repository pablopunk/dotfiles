return {
  os = { "macos" },
  brew = {
    "stats",
  },
  defaults = {
    {
      plist = "./Stats.plist",
      app = "eu.exelban.Stats",
    },
  },
  post_install = [[
    open /Applications/Stats.app
  ]]
}
