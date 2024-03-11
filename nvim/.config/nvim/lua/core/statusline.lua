local utils = require "core.utils"
local hi = utils.hi

Statusline = {}

local align_right = "%="

Statusline.active = function()
  local filename = utils.get_filename_compact()
  local clients = utils.get_lsp_clients_string()

  vim.cmd [[ hi StatusLineClients guifg=#29a4bd guibg=#1f2335 ]]

  return string.format("%s %s %s", filename, align_right, hi "StatusLineClients"(clients))
end

Statusline.inactive = function()
  return "%t" -- just the file name
end

vim.cmd [[
  augroup Statusline
  au!
  au WinEnter,BufEnter * setlocal statusline=%!v:lua.Statusline.active()
  au WinLeave,BufLeave * setlocal statusline=%!v:lua.Statusline.inactive()
  augroup END
]]
