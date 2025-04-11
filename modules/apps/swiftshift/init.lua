return {
  brew = {
    "swift-shift",
  },
  defaults = {
    {
      plist = "./SwiftShift.plist",
      app = "com.pablopunk.Swift-Shift",
    },
  },
  post_install = [[
    open "/Applications/Swift Shift.app"
  ]]
}
