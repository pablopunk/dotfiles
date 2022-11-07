local c_status, cmp = pcall(require, "cmp")
if not c_status then
  print "cmp not found"
  return
end

local l_status, luasnip = pcall(require, "luasnip")
if not l_status then
  print "luasnip not found"
  return
end

local lspkind_status, lspkind = pcall(require, "lspkind") -- icons for the autocompletion
if not lspkind_status then
  print "lspkind not found"
  return
end

-- load friendly-snippets
require("luasnip/loaders/from_vscode").lazy_load()

vim.opt.completeopt = "menu,menuone,noselect"

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    -- ["<c-n>"] = cmp.mapping.complete(), -- show suggestions window
    ["<cr>"] = cmp.mapping.confirm { select = false }, -- choose suggestion
  },
  sources = cmp.config.sources {
    { name = "nvim_lsp" }, -- lsp
    { name = "luasnip" }, -- snippets
    { name = "buffer" }, -- text in buffer
    { name = "path" }, -- file system paths
  },
  formatting = {
    format = lspkind.cmp_format { ellipsis_char = "...", maxwidth = 50 },
  },
}
