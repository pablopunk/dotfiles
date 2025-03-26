return {
  os = { "mac" }, -- NOTE TO SELF: PLEASE IMPLEMENT THIS LIKE RIGHT NOW
  brew = {
    "1password",
    "aldente",
    "arc",
    "cleanshot",
    "iina",
    "jordanbaird-ice",
    "karabiner-elements",
    "latest",
    "missive",
    "notion-calendar",
    "pablopunk/brew/swift-shift",
    "raycast",
    "sf-symbols",
    "spacelauncher",
    "spotify",
    "stats",
    "tailscale",
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
      plist = "./defaults/CleanShotX.plist",
      app = "pl.maketheweb.cleanshotx",
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
    {
      plist = "./defaults/SpaceLauncher.plist",
      app = "name.guoc.SpaceLauncher",
    },
  },
}
