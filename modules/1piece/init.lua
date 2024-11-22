return {
  wget = {
    url = "https://app1piece.com/1Piece-4.2.1.zip",
    output = "/Applications/1Piece.app",
    zip = true,
  },
  post_install = [[
    open ~/.dotfiles/modules/1piece/1Piece.app-settings
    open -a 1Piece
  ]],
}
