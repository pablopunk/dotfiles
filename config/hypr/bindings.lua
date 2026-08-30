-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- HYPER = SUPER + CTRL + ALT
local SUPER = "SUPER"
local SUPER_SHIFT = SUPER .. " + SHIFT"
local HYPER = SUPER .. " + CTRL + ALT"
local HYPER_SHIFT = HYPER .. " + SHIFT"

local function combo(modifier, key)
  return modifier .. " + " .. key
end

local function bind_hyper(key, description, dispatcher)
  local super_key = combo(SUPER, key)
  local hyper_key = combo(HYPER, key)

  hl.unbind(super_key)
  hl.unbind(hyper_key)
  o.bind(hyper_key, description, dispatcher)
end

-- Toggle Mousetrap's keyboard grid.
o.bind(combo(HYPER, "SPACE"), "Toggle Mousetrap", hl.dsp.global("mousetrap:toggle"))

-- Close the active window.
hl.unbind(combo(SUPER, "W"))  -- was: Close window
o.bind(combo(SUPER, "Q"), "Close window", hl.dsp.window.close())

-- New terminal: HYPER+T (replaces SUPER+RETURN).
hl.unbind(combo(SUPER, "RETURN"))  -- was: Terminal
bind_hyper("T", "Terminal", { omarchy = "terminal" })

-- Vim-style window focus with HYPER + h/j/k/l.
-- Falls back to next/previous workspace when no window in that direction.
-- When hopping, lands on the window at the edge we entered from:
--   right -> leftmost window of the next workspace
--   left  -> rightmost window of the previous workspace
--   down  -> topmost window of the next workspace
--   up    -> bottommost window of the previous workspace
local function focus_or_workspace(direction)
  local before = hl.get_active_window()
  local before_address = before and before.address
  hl.dispatch(hl.dsp.focus({ direction = direction }))
  local after = hl.get_active_window()
  local after_address = after and after.address
  if before_address == after_address then
    local fallback = (direction == "l" or direction == "u") and "e-1" or "e+1"
    hl.dispatch(hl.dsp.focus({ workspace = fallback }))

    -- Focus the edge window on the workspace we just entered.
    local horizontal = direction == "l" or direction == "r"
    -- +1 -> minimize coordinate (leftmost/topmost), -1 -> maximize (rightmost/bottommost).
    local sign = (direction == "r" or direction == "d") and 1 or -1

    local monitor = hl.get_active_monitor()
    if monitor and monitor.active_workspace then
      local ws_id = monitor.active_workspace.id
      local best = nil
      local best_key = nil
      for _, w in ipairs(hl.get_windows()) do
        if w.visible and w.workspace and w.workspace.id == ws_id
          and w.monitor and w.monitor.id == monitor.id
          and type(w.at) == "table" and type(w.size) == "table"
        then
          local cx = w.at.x + w.size.x / 2
          local cy = w.at.y + w.size.y / 2
          -- Tie-break along the other axis: topmost for l/r, leftmost for u/d.
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

local directional_bindings = {
  { key = "H", direction = "l", focus_description = "Focus left, or previous workspace", swap_description = "Swap window to the left" },
  { key = "J", direction = "d", focus_description = "Focus down, or next workspace", swap_description = "Swap window down" },
  { key = "K", direction = "u", focus_description = "Focus up, or previous workspace", swap_description = "Swap window up" },
  { key = "L", direction = "r", focus_description = "Focus right, or next workspace", swap_description = "Swap window to the right" },
}

local function bind_focus(binding)
  bind_hyper(binding.key, binding.focus_description, function()
    focus_or_workspace(binding.direction)
  end)
end

for _, binding in ipairs(directional_bindings) do
  bind_focus(binding)
end

-- fullscreen and floating
o.bind(combo(HYPER, "F"), "Toggle window floating", hl.dsp.window.float({ action = "toggle" }))
o.bind(combo(HYPER_SHIFT, "F"), "Zoom window to edges", hl.dsp.window.fullscreen({ mode = "maximized" }))
-- o.bind("SUPER + CTRL + ALT + SHIFT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Toggle workspace layout (dwindle <-> scrolling) with HYPER+A.
bind_hyper("A", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- Pseudo window: HYPER+P (replaces SUPER+P).
hl.unbind(combo(SUPER, "P"))  -- was: Pseudo window
o.bind(combo(HYPER, "P"), "Pseudo window", hl.dsp.window.pseudo())

-- Resize the active window: HYPER+- shrinks a bit, HYPER++ grows a bit.
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

local resize_bindings = {
  { key = "MINUS", description = "Shrink window a bit", grow = false },
  -- Bound to both keysyms: "+" key sends `plus` on the ES layout, `equal` on US.
  { key = "PLUS", description = "Grow window a bit", grow = true },
  { key = "EQUAL", description = "Grow window a bit", grow = true },
}

local function bind_resize(binding)
  o.bind(combo(HYPER, binding.key), binding.description, function()
    resize_window_step(binding.grow)
  end)
end

for _, binding in ipairs(resize_bindings) do
  bind_resize(binding)
end

-- Area screenshot: HYPER+S.
o.bind(combo(HYPER, "S"), "Area screenshot", "omarchy-capture-screenshot region")

-- Fullscreen screenshot: HYPER+SHIFT+S.
o.bind(combo(HYPER_SHIFT, "S"), "Fullscreen screenshot", "omarchy-capture-screenshot fullscreen")

-- Switch workspaces with HYPER + 1-10.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind(combo(HYPER, key), "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind(combo(HYPER_SHIFT, key), "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

-- Previously visited workspace: HYPER+TAB.
o.bind(combo(HYPER, "TAB"), "Former workspace", hl.dsp.focus({ workspace = "previous" }))

-- Move windows with HYPER + SHIFT + h/j/k/l.
for _, binding in ipairs(directional_bindings) do
  o.bind(combo(HYPER_SHIFT, binding.key), binding.swap_description, hl.dsp.window.swap({ direction = binding.direction }))
end

-- Window overview: HYPER+O.
-- hyprview doesn't build on Hyprland 0.56.2 yet; binding is inert until then.
o.bind(combo(HYPER, "O"), "Window overview", "hyprctl dispatch hyprview:toggle")

-- Helium: HYPER+G.
bind_hyper("G", "Helium", { launch = "helium-browser" })

-- Disable SUPER+SHIFT+SPACE (was: Toggle top bar).
hl.unbind(combo(SUPER_SHIFT, "SPACE"))

-- Dictation: HYPER+V hold-to-talk (release to transcribe).
local dictation_key = combo(HYPER, "V")
o.bind(dictation_key, "Start dictation (hold to talk)", "voxtype record start")
o.bind(dictation_key, "Stop dictation (hold to talk)", "voxtype record stop", { release = true })

-- Clipboard manager: SUPER+SHIFT+V (same action as the default SUPER+CTRL+V).
o.bind(combo(SUPER_SHIFT, "V"), "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")
