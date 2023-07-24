local lspconfig_status, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status then
  print "lspconfig not found"
  return
end

local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
  print "cmp_nvim_lsp not found"
  return
end

local typescript_status, typescript = pcall(require, "typescript")
if not typescript_status then
  print "typescript not found"
  return
end

local keymap = vim.keymap

-- enable keybinds for available lsp server
local on_attach = function(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<cr>", opts)
  keymap.set("n", "gt", "<cmd>Lspsaga peek_definition<cr>", opts)
  keymap.set("n", "gv", "<cmd>Lspsaga finder<cr>", opts)
  keymap.set("n", "gr", "<cmd>Lspsaga rename<cr>", opts)
  keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<cr>", opts)
  keymap.set("n", "K", "<cmd>Lspsaga hover_doc<cr>", opts)
  keymap.set("n", "E", "<cmd>Lspsaga show_line_diagnostics<cr>", opts)

  if client.name == "tsserver" then
    keymap.set("n", "<leader>r", ":TypescriptRenameFile<cr>")
  end

  -- disable folding for lsp finder
  -- vim.cmd [[augroup lsp_finder]]
  -- vim.cmd [[autocmd!]]
  -- vim.cmd [[autocmd FileType lspsagafinder setlocal nofoldenable]]
  -- vim.cmd [[autocmd FileType markdown setlocal nofoldenable]]
  -- vim.cmd [[augroup END]]
end

-- enable autocompletion
local capabilities = cmp_nvim_lsp.default_capabilities()

lspconfig["html"].setup {
  capabilities = capabilities,
  on_attach = on_attach,
}
lspconfig["cssls"].setup {
  capabilities = capabilities,
  on_attach = on_attach,
}
lspconfig["tailwindcss"].setup {
  capabilities = capabilities,
  on_attach = on_attach,
}
lspconfig["lua_ls"].setup {
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
          [vim.fn.expand "%VIMRUNTIME/lua"] = true,
          [vim.fn.stdpath "config" .. "/lua"] = true,
        },
      },
    },
  },
}

typescript.setup {
  server = {
    capabilities = capabilities,
    on_attach = on_attach,
  },
}
