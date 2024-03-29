local shared = require "core.shared"
local map = shared.map

if vim.g.neovide then
  map({ "n", "v" }, "<D-v>", '"+P', "Paste (neovide)") -- Paste normal and visual mode
  map({ "i", "c" }, "<D-v>", "<C-R>+", "Paste (neovide)") -- Paste insert and command mode
  map("t", "<D-v>", [[<C-\><C-N>"+P]], "Paste (neovide)") -- Paste terminal mode
  vim.g.neovide_transparency = 0.9
  vim.g.neovide_window_blurred = true
  vim.g.neovide_floating_blur_amount_x = 2
  vim.g.neovide_floating_blur_amount_y = 2
  vim.o.guifont = "SF Mono Powerline:h15" -- text below applies for VimScript
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_right = 0
  vim.g.neovide_padding_left = 0
end

return {}
