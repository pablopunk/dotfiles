return {
  os = { "macos" },
  brew = {
    "swift-shift",
  },
  defaults = {
    {
      plist = "./SwiftShift.xml",
      app = "com.pablopunk.Swift-Shift",
    },
  },
  post_install = [[
    open "/Applications/Swift Shift.app"
  ]],
}
