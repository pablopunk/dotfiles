return {
  brew = {
    "1password",
    "aldente",
    "arc",
    "cleanshot",
    "iina",
    "karabiner-elements",
    "latest",
    "missive",
    "notion-calendar",
    "pablopunk/brew/swift-shift",
    "raycast",
    "sf-symbols",
    "spotify",
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
  defaults = {
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
  },
  -- I'm using defaults while I don't make dot compatible.
  -- Search for an app id like so: defaults domains | tr ', ' '\n' | grep -i 1Piece
  post_install = [[
    defaults import jp.fuji.1Piece ~/.dotfiles/modules/apps/personal/defaults/1Piece.plist
    defaults import pl.maketheweb.cleanshotx ~/.dotfiles/modules/apps/personal/defaults/CleanShotX.plist
    defaults import com.apphousekitchen.aldente-pro ~/.dotfiles/modules/apps/personal/defaults/AlDente.plist
    open -a "1Piece"
    open -a "AlDente"
    open -a "CleanShot X"
    open -a "Karabiner-Elements"
    open -a "Raycast"
    open -a "Swift Shift"
  ]],
}
