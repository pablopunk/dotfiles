local mason_status, mason = pcall(require, "mason")
if not mason_status then
  return
end

local m_config, lspconfig = pcall(require, "mason-lspconfig")
if not m_config then
  return
end

mason.setup({})

lspconfig.setup({
  ensure_installed = {
    "tsserver",
    "html",
    "cssls",
    "tailwindcss",
    "sumneko_lua",
  }
})
