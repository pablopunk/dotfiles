return {
  os = { "macos" },
  wget = {
    {
      url = "https://app1piece.com/1Piece-4.2.1.zip",
      output = "/Applications/1Piece.app",
      zip = true,
    },
  },
  defaults = {
    {
      plist = "./1Piece.xml",
      app = "jp.fuji.1Piece",
    },
  },
  post_install = [[
    open /Applications/1Piece.app
  ]]
}
