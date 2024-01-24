-- Plugins to develop plugins in Lua
return {
  { "folke/neodev.nvim", config = true }, -- lsp for developing neovim plugins
  {
    "tjdevries/tree-sitter-lua", -- to generate docs in plugins
    enabled = false, -- DON'T ENABLE IT. I only wanna install it and use it on plugins, not on my config
  },
}
