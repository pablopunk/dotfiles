return {
  os = { "macos" },
  check = "[ -d '/Applications/Swift Shift.app' ]",
  install = {
    brew = "brew install swift-shift",
  },
  defaults = {
    ["com.pablopunk.Swift-Shift"] = "./SwiftShift.xml",
  },
  postinstall = [[
    open "/Applications/Swift Shift.app"
  ]],
}
