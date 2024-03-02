local utils = require "core.utils"

local M = {}

local align_right = "%="

local hi = function(highlight_group)
  return function(text)
    return "%#" .. highlight_group .. "#" .. text .. "%*"
  end
end

M.create_statusline_string = function()
  local filename = vim.fn.expand "%:p"
  local path_segments = vim.split(filename, "/")
  if #path_segments > 1 then
    filename = path_segments[#path_segments - 1] .. "/" .. path_segments[#path_segments]
  else
    filename = path_segments[#path_segments]
  end
  local clients = utils.get_lsp_clients_string()

  vim.cmd [[ hi StatusLineClients guifg=#29a4bd guibg=#1f2335 ]]

  return filename .. align_right .. hi "StatusLineClients"(clients)
end

vim.o.statusline = "%!v:lua.require('core.statusline').create_statusline_string()"

return M
