local utils = require "core.utils"
local hi = utils.hi

Statusline = {}

local align_right = "%="

local _color_highlights = false -- run fn only once
local function color_highlights()
  if _color_highlights then
    return
  end

  ---@type 'dark' | 'light'
  local theme = vim.api.nvim_get_option "background"

  if theme == "dark" then
    vim.cmd [[ hi StatusLineClients guifg=#29a4bd guibg=#1f2335 ]]
  else
    vim.cmd [[ hi StatusLineClients guifg=#29a4bd guibg=#e9e9ec ]]
  end

  _color_highlights = true
end

Statusline.active = function()
  local filename = utils.get_filename_compact()
  local clients = utils.get_lsp_clients_string()

  color_highlights()

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
