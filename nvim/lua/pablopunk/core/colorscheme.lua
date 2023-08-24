local function dark_mode()
  vim.cmd "silent! set background=dark"
  vim.cmd "silent! colorscheme catppuccin"
end

local function light_mode()
  vim.cmd "silent! set background=light"
  vim.cmd "silent! colorscheme catppuccin-latte"
end

local handle = io.popen "cat $HOME/.theme"
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

