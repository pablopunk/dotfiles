local function dark_mode()
  -- vim.cmd "silent! let ayucolor='dark'"
  vim.cmd "silent! let ayucolor='mirage'"
  vim.cmd "silent! colorscheme ayu"
end

local function light_mode()
  vim.cmd "silent! let ayucolor='light'"
  vim.cmd "silent! colorscheme ayu"
end

local handle = io.popen "defaults read -g AppleInterfaceStyle"
if not handle then
  dark_mode() -- default to dark mode
  return
end

local result = handle:read "*a"
handle:close()

if string.match(result, "Dark") then
  dark_mode()
elseif string.match(result, "not found") then
  dark_mode() -- unknown, default to dark mode
else
  light_mode()
end
