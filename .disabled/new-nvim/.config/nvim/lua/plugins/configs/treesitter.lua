local M = {}

M.treesitter = {
  ensure_installed = { "lua", "vimdoc", "rust", "ocaml", "markdown" },
  highlight = {
    enable = true,
    use_languagetree = true,
  },

  indent = { enable = true },
}

return M
