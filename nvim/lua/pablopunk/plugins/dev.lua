-- Plugins to develop plugins in Lua
return {
  { "folke/neodev.nvim", config = true }, -- lsp for developing neovim plugins
  {
    "tjdevries/tree-sitter-lua",
    build = "make build_parser && rsync -u ./build/parser.so ./parser/lua.so", -- fix while this is not merged https://github.com/tjdevries/tree-sitter-lua/pull/53
  }, -- to generate docs in plugins
}
