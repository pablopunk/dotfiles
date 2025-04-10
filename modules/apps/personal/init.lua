return {
  os = { "mac" }, -- NOTE TO SELF: PLEASE IMPLEMENT THIS LIKE RIGHT NOW
  brew = {
    "1password",
    "aldente",
    "arc",
    "iina",
    "jordanbaird-ice",
    "karabiner-elements",
    "latest",
    "missive",
    "notion-calendar",
    "swift-shift",
    "raycast",
    "sf-symbols",
    "spotify",
    "stats",
    "homebrew/cask/tailscale",
    "whatsapp",
    "zed",
  },
  wget = {
    {
      url = "https://app1piece.com/1Piece-4.2.1.zip",
      output = "/Applications/1Piece.app",
      zip = true,
    },
  },
  -- defaults domains | tr ', ' '\n' | grep -i <app-name>
  defaults = {
    {
      plist = "./defaults/Stats.plist",
      app = "eu.exelban.Stats",
    },
    {
      plist = "./defaults/1Piece.plist",
      app = "jp.fuji.1Piece",
    },
    {
      plist = "./defaults/AlDente.plist",
      app = "com.apphousekitchen.aldente-pro",
    },
    {
      plist = "./defaults/SwiftShift.plist",
      app = "com.pablopunk.Swift-Shift",
    },
    {
      plist = "./defaults/Ice.plist",
      app = "com.jordanbaird.Ice",
    },
  },
  post_install = [[
    open /Applications/Ice.app
    open /Applications/Stats.app
    open /Applications/1Piece.app
    open /Applications/AlDente.app
    open /Applications/SwiftShift.app
    open /Applications/SpaceLauncher.app
  ]]
}
