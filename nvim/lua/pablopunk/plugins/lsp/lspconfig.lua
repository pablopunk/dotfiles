local lspconfig_status, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status then
  print("lspconfig not found")
  return
end

local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
  print("cmp_nvim_lsp not found")
  return
end

local typescript_status, typescript = pcall(require, "typescript")
if not typescript_status then
  print("typescript not found")
  return
end

local keymap = vim.keymap

-- enable keybinds for available lsp server
local on_attach = function(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  keymap.set("n", "gd", "<cmd>Lspsaga lsp_finder<cr>", opts)
  keymap.set("n", "<leader>r", "<cmd>Lspsaga rename<cr>", opts)
  keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<cr>", opts)
  keymap.set("n", "K", "<cmd>Lspsaga hover_doc<cr>", opts)
  keymap.set("n", "<leader>o", "<cmd>LSoutlineToggle<cr>", opts)
  keymap.set("n", "ge", "<cmd>Lspsaga diagnostic_jump_next<cr>", opts)
  keymap.set("n", "gE", "<cmd>Lspsaga diagnostic_jump_prev<cr>", opts)

  if client.name == "tsserver" then
    keymap.set("n", "<leader>R", ":TypescriptRenameFile<cr>")
  end
end

-- enable autocompletion
local capabilities = cmp_nvim_lsp.default_capabilities()

lspconfig["html"].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
lspconfig["cssls"].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
lspconfig["tailwindcss"].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
lspconfig["sumneko_lua"].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        -- make server aware of runtime files
        library = {
          [vim.fn.expand("%VIMRUNTIME/lua")] = true,
          [vim.fn.stdpath("config") .. "/lua"] = true,
        },
      },
    },
  },
})

typescript.setup({
  server = {
    capabilities = capabilities,
    on_attach = on_attach,
  },
})
