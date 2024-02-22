local icons = require "core.icons"

local M ={}

M.gitsigns = {
  signs = {
    add = { text = "" .. icons.gitsigns.add },
    change = { text = "" .. icons.gitsigns.change },
    delete = { text = "" .. icons.gitsigns.delete },
    topdelete = { text = "" .. icons.gitsigns.topdelete },
    changedelete = { text = "" .. icons.gitsigns.changedelete },
    untracked = { text = "" .. icons.gitsigns.untracked },
  },
  on_attach = function()
    -- require("core.keymaps").gitsigns()
  end,
}

return M
