return {
  os = { "mac" },
  brew = {
    "FelixKratz/formulae/sketchybar",
    "switchaudio-osx",
    "nowplaying-cli",
    "font-sf-mono --cask",
    "font-sf-pro --cask",
    "sf-symbols --cask",
  },
  config = {
    source = "./config",
    output = "~/.config/sketchybar",
  },
  post_install = [[
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)
brew services restart sketchybar
]],
}
