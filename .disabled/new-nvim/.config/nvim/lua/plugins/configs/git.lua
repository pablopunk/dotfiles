local M = { }

M.gitsigns = {
  signcolumn = false,
  numhl = true,
  on_attach = function()
    require("core.keymaps").gitsigns()
  end,
}

return M
