return {
  os = { "macos" },
  brew = {
    "jordanbaird-ice",
  },
  defaults = {
    {
      plist = "./Ice.xml",
      app = "com.jordanbaird.Ice",
    },
  },
  post_install = [[
    open /Applications/Ice.app
  ]]
}
