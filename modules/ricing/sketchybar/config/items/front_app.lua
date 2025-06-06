local colors = require "colors"
local settings = require "settings"

local front_app = sbar.add("item", "front_app", {
  display = "active",
  icon = { drawing = true },
  label = {
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
    padding_left = 3,
    padding_right = 9,
    color = colors.fg,
  },
  background = {
    color = colors.bg,
    height = 24,
    corner_radius = 100,
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set { label = { string = env.INFO } }
end)

front_app:subscribe("mouse.clicked", function(env)
  sbar.trigger "swap_menus_and_spaces"
end)
