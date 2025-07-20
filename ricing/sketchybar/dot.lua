return {
  os = { "macos" },
  check = "which sketchybar",
  install = {
    brew = "brew install FelixKratz/formulae/sketchybar switchaudio-osx nowplaying-cli font-sf-mono font-sf-pro sf-symbols",
  },
  link = {
    ["./config"] = "~/.config/sketchybar",
  },
  postinstall = [[
    curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
    (git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)
    brew services restart sketchybar
  ]],
}
