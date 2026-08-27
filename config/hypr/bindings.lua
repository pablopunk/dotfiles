-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Close the active window.
hl.unbind("SUPER + W")  -- was: Close window
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- Focus with arrows, falling back to the adjacent workspace at an edge.
local function focus_or_workspace(direction)
  local before = hl.get_active_window()
  local before_address = before and before.address
  hl.dispatch(hl.dsp.focus({ direction = direction }))
  local after = hl.get_active_window()
  local after_address = after and after.address
  if before_address == after_address then
    local fallback = (direction == "l" or direction == "u") and "e-1" or "e+1"
    hl.dispatch(hl.dsp.focus({ workspace = fallback }))

    local horizontal = direction == "l" or direction == "r"
    local sign = (direction == "r" or direction == "d") and 1 or -1
    local monitor = hl.get_active_monitor()
    if monitor and monitor.active_workspace then
      local ws_id = monitor.active_workspace.id
      local best, best_key
      for _, w in ipairs(hl.get_windows()) do
        if w.visible and w.workspace and w.workspace.id == ws_id
          and w.monitor and w.monitor.id == monitor.id
          and type(w.at) == "table" and type(w.size) == "table"
        then
          local cx = w.at.x + w.size.x / 2
          local cy = w.at.y + w.size.y / 2
          local key = horizontal and (sign * cx + cy / 100000) or (sign * cy + cx / 100000)
          if best_key == nil or key < best_key then
            best_key = key
            best = w
          end
        end
      end
      if best then
        hl.dispatch(hl.dsp.focus({ window = "address:" .. best.address }))
      end
    end
  end
end

hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
o.bind("SUPER + LEFT", "Focus left, or previous workspace", function() focus_or_workspace("l") end)
o.bind("SUPER + RIGHT", "Focus right, or next workspace", function() focus_or_workspace("r") end)
o.bind("SUPER + UP", "Focus up, or previous workspace", function() focus_or_workspace("u") end)
o.bind("SUPER + DOWN", "Focus down, or next workspace", function() focus_or_workspace("d") end)

-- Terminal on SUPER+T.
hl.unbind("SUPER + T")  -- was: Toggle window floating
o.bind("SUPER + T", "Terminal", { omarchy = "terminal" })

-- Fullscreen and floating.
hl.unbind("SUPER + F")
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + F", "Toggle window floating", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + SHIFT + F", "Zoom window to edges", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Resize the active window with SUPER+- and SUPER+plus.
-- Works in tiled, floating, and pseudo mode (pseudo windows stay centered).
-- Tune RESIZE_STEP to change the step size (5% of the window per press).
local RESIZE_STEP = 0.05

local function resize_window_step(grow)
  local win = hl.get_active_window()
  if not win or not win.size then
    return
  end
  local factor = 1 + (grow and RESIZE_STEP or -RESIZE_STEP)
  local x = math.max(80, math.floor(win.size.x * factor + 0.5))
  local y = math.max(80, math.floor(win.size.y * factor + 0.5))
  if grow then
    -- Don't grow past the screen (window sizes use scaled coordinates).
    local monitor = hl.get_active_monitor()
    if monitor then
      x = math.min(x, math.floor(monitor.width / monitor.scale))
      y = math.min(y, math.floor(monitor.height / monitor.scale))
    end
  end
  hl.dispatch(hl.dsp.window.resize({ x = x, y = y, relative = false }))
end

hl.unbind("SUPER + MINUS")
hl.unbind("SUPER + PLUS")
hl.unbind("SUPER + EQUAL")
hl.unbind("SUPER + code:20")
hl.unbind("SUPER + code:21")
o.bind("SUPER + MINUS", "Shrink window a bit", function() resize_window_step(false) end)
-- Bound to both keysyms: "+" key sends `plus` on the ES layout, `equal` on US.
o.bind("SUPER + PLUS", "Grow window a bit", function() resize_window_step(true) end)
o.bind("SUPER + EQUAL", "Grow window a bit", function() resize_window_step(true) end)

-- Screenshot on SUPER+S.
hl.unbind("SUPER + S")  -- was: Toggle scratchpad
o.bind("SUPER + S", "Screenshot", "omarchy-capture-screenshot")

-- Previously visited workspace on SUPER+TAB.
hl.unbind("SUPER + TAB")
o.bind("SUPER + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))

-- Screenshots: SUPER+SHIFT+3 fullscreen, SUPER+SHIFT+4 area.
hl.unbind("SUPER + SHIFT + code:12")  -- was: Move window to workspace 3
hl.unbind("SUPER + SHIFT + code:13")  -- was: Move window to workspace 4
o.bind("SUPER + SHIFT + code:12", "Fullscreen screenshot", "omarchy-capture-screenshot fullscreen")
o.bind("SUPER + SHIFT + code:13", "Area screenshot", "omarchy-capture-screenshot region")

-- Helium on SUPER+G.
hl.unbind("SUPER + G")  -- was: Toggle window grouping
o.bind("SUPER + G", "Helium", { launch = "helium-browser" })

-- Disable SUPER+SHIFT+SPACE (was: Toggle top bar).
hl.unbind("SUPER + SHIFT + SPACE")

-- Clipboard manager: SUPER+SHIFT+V (same action as the default SUPER+CTRL+V).
o.bind("SUPER + SHIFT + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")
