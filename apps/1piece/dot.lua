return {
  os = { "macos" },
  check = "[ -d '/Applications/1Piece.app' ]",
  install = {
    wget = "wget https://app1piece.com/1Piece-4.2.1.zip -O /Applications/1Piece.app",
  },
  defaults = {
    ["jp.fuji.1Piece"] = "./1Piece.xml",
  },
  postinstall = [[
    open /Applications/1Piece.app
  ]],
}
