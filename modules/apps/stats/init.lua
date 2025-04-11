return {
  os = { "macos" },
  brew = {
    "stats",
  },
  defaults = {
    {
      plist = "./Stats.xml",
      app = "eu.exelban.Stats",
    },
  },
  post_install = [[
    open /Applications/Stats.app
  ]]
}
