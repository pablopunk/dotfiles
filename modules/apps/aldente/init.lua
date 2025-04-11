return {
  brew = {
    "aldente",
  },
  defaults = {
    {
      plist = "./AlDente.plist",
      app = "com.apphousekitchen.aldente-pro",
    },
  },
  post_install = [[
    open /Applications/AlDente.app
  ]]
}
