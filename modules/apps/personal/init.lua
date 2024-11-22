return {
  brew = {
    "1password",
    "aldente",
    "alt-tab",
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
    {
      url = "https://www.dropbox.com/scl/fi/lziq2egjb0e4twszlbu9b/Supercharge-1.7.0-trial-1732193286.zip?rlkey=vqoqknmzuo7yiryzyddkoxwo0&raw=1",
      output = "/Applications/Supercharge.app",
      zip = true,
    },
  },
  post_install = [[
    open -a "1Piece"
    open -a "AlDente"
    open -a "AltTab"
    open -a "CleanShot X"
    open -a "Karabiner-Elements"
    open -a "Raycast"
    open -a "Supercharge"
    open -a "Swift Shift"
    open -a "Visual Studio Code"
    open ~/.dotfiles/modules/apps/personal/1Piece.app-settings
    open ~/.dotfiles/modules/apps/personal/AlDente.app-settings
  ]],
}
