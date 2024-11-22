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
  post_install = [[
    open -a "1Piece"
    open -a "AlDente"
    open -a "CleanShot X"
    open -a "Karabiner-Elements"
    open -a "Raycast"
    open -a "Swift Shift"
    defaults import jp.fuji.1Piece ~/.dotfiles/modules/apps/personal/1Piece.plist
    defaults import pl.maketheweb.cleanshotx ~/.dotfiles/modules/apps/personal/CleanShotX.plist
    defaults import com.apphousekitchen.aldente-pro ~/.dotfiles/modules/apps/personal/AlDente.plist
  ]], -- use defaults while I don't make dot compatible. To see app id: defaults domains | tr ', ' '\n' | grep -i 1Piece
}
