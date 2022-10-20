require("nvim-treesitter.configs").setup({
  highlight = {
    enable = true,
  },
  indent = { enable = true },
  autotag = { enable = true }, -- requires nvim-ts-autotag
  ensure_installed = { -- if these are not installed, it will install them
    "json",
    "javascript",
    "typescript",
    "tsx",
    "yaml",
    "html",
    "css",
    "markdown",
    "graphql",
    "bash",
    "lua",
    "vim",
    "gitignore",
  },
  auto_install = true,
})
