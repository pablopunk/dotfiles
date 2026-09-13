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
-- Hyprland 0.56.2 silently drops "SPACE"-keysym binds with SHIFT during
-- config load, so the bind uses the space keycode (57) instead of the keysym.
hl.unbind(combo(SUPER_SHIFT, "SPACE"))  -- was: Toggle top bar
o.bind("SUPER + SHIFT + code:57", "Toggle Mousetrap", hl.dsp.global("mousetrap:toggle"))

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
  { key = "H", direction = "l", focus_description = "Focus left, or previous workspace", move_description = "Move/stack window left" },
  { key = "J", direction = "d", focus_description = "Focus down, or next workspace", move_description = "Move window down in column" },
  { key = "K", direction = "u", focus_description = "Focus up, or previous workspace", move_description = "Move window up in column" },
  { key = "L", direction = "r", focus_description = "Focus right, or next workspace", move_description = "Move/stack window right" },
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

-- Resize the active window through size presets.
-- HYPER+. steps up, HYPER+, steps down, wrapping around at the ends.
-- In the scrolling layout this cycles the native column-width presets
-- (scrolling.explicit_column_widths, set in looknfeel.lua); in other layouts
-- the window itself is resized to the preset fraction of the monitor.
local RESIZE_PRESETS = { 0.33, 0.50, 0.67, 0.85 }

-- Index of the next preset in `direction` (+1 up, -1 down) from the current
-- width fraction, skipping the preset the window is already at.
-- The epsilon absorbs the gaps/borders around the window.
local function next_preset_index(current, direction)
  local epsilon = 0.02
  if direction > 0 then
    for i, preset in ipairs(RESIZE_PRESETS) do
      if preset > current + epsilon then
        return i
      end
    end
    return 1
  end
  for i = #RESIZE_PRESETS, 1, -1 do
    if RESIZE_PRESETS[i] < current - epsilon then
      return i
    end
  end
  return #RESIZE_PRESETS
end

local function resize_window_preset(direction)
  local win = hl.get_active_window()
  local monitor = hl.get_active_monitor()
  if not win or not win.size or not monitor then
    return
  end

  -- In the scrolling layout, absolute resizeactive gets clamped by the
  -- viewport (which made the presets creep in increments), so use the
  -- layout's own preset cycle instead.
  local workspace = monitor.active_workspace
  if not win.floating and workspace and workspace.tiled_layout == "scrolling" then
    hl.dispatch(hl.dsp.layout(direction > 0 and "colresize +conf" or "colresize -conf"))
    return
  end

  -- Window and monitor sizes use the same scaled (logical) coordinates.
  local monitor_width = monitor.width / monitor.scale
  local monitor_height = monitor.height / monitor.scale
  local preset = RESIZE_PRESETS[next_preset_index(win.size.x / monitor_width, direction)]
  hl.dispatch(hl.dsp.window.resize({
    x = math.floor(monitor_width * preset + 0.5),
    y = math.floor(monitor_height * preset + 0.5),
    relative = false,
  }))
end

local resize_bindings = {
  -- Keysym names must be lower-case: xkbcommon calls this key "comma",
  -- and the upper-case "COMMA" does not match (same note in omarchy defaults).
  { key = "comma", description = "Previous size preset", direction = -1 },
  { key = "period", description = "Next size preset", direction = 1 },
}

local function bind_resize(binding)
  o.bind(combo(HYPER, binding.key), binding.description, function()
    resize_window_preset(binding.direction)
  end)
end

for _, binding in ipairs(resize_bindings) do
  bind_resize(binding)
end

-- Area screenshot: HYPER+S.
o.bind(combo(HYPER, "S"), "Area screenshot", "omarchy-capture-screenshot")

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
-- In the scrolling layout, left/right walk a window across columns: it joins
-- the neighbouring column when it is alone and pops back out into its own
-- column when it is already stacked (the layout's consume_or_expel pair).
-- Up/down reorder within the column. Other layouts use the normal move.
local function move_window(direction)
  local monitor = hl.get_active_monitor()
  local layout = monitor and monitor.active_workspace and monitor.active_workspace.tiled_layout
  if layout == "scrolling" and direction == "l" then
    hl.dispatch(hl.dsp.layout("consume_or_expel prev"))
  elseif layout == "scrolling" and direction == "r" then
    hl.dispatch(hl.dsp.layout("consume_or_expel next"))
  else
    hl.dispatch(hl.dsp.window.move({ direction = direction }))
  end
end

for _, binding in ipairs(directional_bindings) do
  o.bind(combo(HYPER_SHIFT, binding.key), binding.move_description, function()
    move_window(binding.direction)
  end)
end

-- Window overview: HYPER+O.
-- hyprview doesn't build on Hyprland 0.56.2 yet; binding is inert until then.
o.bind(combo(HYPER, "O"), "Window overview", "hyprctl dispatch hyprview:toggle")

-- Browser: HYPER+G.
bind_hyper("G", "Browser", { launch = "omarchy launch browser" })

-- macOS-style app shortcuts: SUPER + key forwards CTRL + key to the focused
-- app, like Omarchy's universal SUPER+C/V/X clipboard bindings.
-- The down/up split works around Hyprland send_shortcut sometimes leaving
-- synthetic key state stuck/repeating.
-- https://github.com/hyprwm/Hyprland/discussions/14099
local function send_ctrl(key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- Any default on these keys is dropped first (SUPER+F was fullscreen).
local app_shortcuts = {
  { key = "T", description = "New tab" },
  { key = "W", description = "Close tab" },
  { key = "R", description = "Reload" },
  { key = "P", description = "Print" },
  { key = "A", description = "Select all" },
  { key = "S", description = "Save" },
  { key = "F", description = "Find" },
  { key = "K", description = "Search" },
  { key = "L", description = "Address bar" },
  { key = "Z", description = "Undo" },
}

for _, shortcut in ipairs(app_shortcuts) do
  hl.unbind(combo(SUPER, shortcut.key))
  o.bind(combo(SUPER, shortcut.key), shortcut.description, send_ctrl(shortcut.key))
end

-- Disable SUPER+SHIFT+SPACE (was: Toggle top bar).
hl.unbind(combo(SUPER_SHIFT, "SPACE"))

-- SUPER+S (was: Toggle scratchpad) is now the app "Save" shortcut above.

-- Dictation: HYPER+V hold-to-talk (release to transcribe).
local dictation_key = combo(HYPER, "V")
o.bind(dictation_key, "Start dictation (hold to talk)", "voxtype record start")
o.bind(dictation_key, "Stop dictation (hold to talk)", "voxtype record stop", { release = true })

-- Clipboard manager: SUPER+SHIFT+V (same action as the default SUPER+CTRL+V).
o.bind(combo(SUPER_SHIFT, "V"), "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

-- Hyprland exposes portal shortcuts through an explicit global dispatcher bind.
o.bind("ALT + SPACE", "Nevermind", hl.dsp.global("com.pablopunk.nvm:2639D857989B655DE11234819A5B5CD9-Alt+Space"))

-- Emojis
hl.unbind(combo(SUPER_SHIFT, "E"))
o.bind(combo(SUPER_SHIFT, "E"), "Emoji", { launch = "omarchy menu emoji" })
