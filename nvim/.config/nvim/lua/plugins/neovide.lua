local utils = require "core.utils"
local map = utils.map

if vim.g.neovide then
  map({ "n", "v" }, "<D-v>", '"+P', "Paste (neovide)") -- Paste normal and visual mode
  map({ "i", "c" }, "<D-v>", "<C-R>+", "Paste (neovide)") -- Paste insert and command mode
  map("t", "<D-v>", [[<C-\><C-N>"+P]], "Paste (neovide)") -- Paste terminal mode
  vim.g.neovide_transparency = 0.9
end

return {}
