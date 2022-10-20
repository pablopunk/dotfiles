local setup, null_ls = pcall(require, "null-ls")
if not setup then
  print("null_ls not found")
  return
end

local lsp_format_status, lsp_format = pcall(require, "lsp-format")
if not lsp_format_status then
  print("lsp_format not found")
  return
end

local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics

lsp_format.setup({}) -- async by default, add {sync=true} if needed

null_ls.setup({
  sources = {
    formatting.stylua.with({ extra_args = { "--indent-type", "Spaces", "--indent-width", "2" } }),
    formatting.prettier,
    diagnostics.eslint_d,
  },
  debug = false,
  -- format on save (async)
  on_attach = lsp_format.on_attach,
})
