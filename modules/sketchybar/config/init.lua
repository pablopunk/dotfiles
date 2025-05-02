-- Require the sketchybar module
sbar = require("sketchybar")

-- Set the bar name, if you are using another bar instance than sketchybar
-- sbar.set_bar_name("bottom_bar")

-- Bundle the entire initial configuration into a single message to sketchybar
sbar.begin_config()

-- Detect if laptop/monitor
local handle =
  io.popen 'system_profiler SPDisplaysDataType | grep -q "Display Type: Built-in" && echo "laptop" || echo "external"'
local result = handle:read "*a"
handle:close()

if result:find "laptop" then
  require "bar-laptop"
else
  require "bar"
end

require("default")
require("items")
sbar.end_config()

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
