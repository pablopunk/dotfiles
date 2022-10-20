local handle = io.popen("defaults read -g AppleInterfaceStyle")
if not handle then
  vim.cmd("silent! colorscheme onedark")
  return
end

local result = handle:read("*a")
handle:close()

if string.match(result, "Dark") then
  vim.cmd("silent! colorscheme onedark")
else
  vim.cmd("silent! colorscheme xcodelight")
end
