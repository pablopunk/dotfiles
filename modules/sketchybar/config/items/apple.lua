local colors = require "colors"
local icons = require "icons"
local settings = require "settings"

-- Padding item required because of bracket
sbar.add("item", { width = 5 })

local apple = sbar.add("item", {
  icon = {
    font = { size = 15.0 },
    string = icons.apple,
    padding_right = 9,
    padding_left = 8,
  },
  label = { drawing = false },
  background = {
    color = colors.bg,
    border_width = 0,
  },
  padding_left = 1,
  padding_right = 6,
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})
