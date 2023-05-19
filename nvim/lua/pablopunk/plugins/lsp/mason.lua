local mason_status, mason = pcall(require, "mason")
if not mason_status then
  return
end

local m_config, lspconfig = pcall(require, "mason-lspconfig")
if not m_config then
  return
end

local null_ls_status, mason_null_ls = pcall(require, "mason-null-ls")
if not null_ls_status then
  return
end

mason.setup {}

lspconfig.setup {
  ensure_installed = {
    "tsserver",
    "html",
    "cssls",
    "tailwindcss",
    "lua_ls",
  },
}

mason_null_ls.setup {
  ensure_installed = {
    "prettier",
    "stylua",
    "eslint_d",
  },
}
