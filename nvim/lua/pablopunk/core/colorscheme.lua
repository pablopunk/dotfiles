local handle = io.popen("defaults read -g AppleInterfaceStyle")
if not handle then
  vim.cmd("colorscheme onedark")
  return
end

local result = handle:read("*a")
handle:close()

if string.match(result, "Dark") then
  vim.cmd("colorscheme onedark")
else
  vim.cmd("colorscheme xcodelight")
end
