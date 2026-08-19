-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- HYPER = SUPER + CTRL + ALT

-- Close the active window.
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- New terminal: HYPER+T (replaces SUPER+RETURN).
hl.unbind("SUPER + RETURN")          -- was: Terminal
hl.unbind("SUPER + CTRL + ALT + T")  -- was: Show time
o.bind("SUPER + CTRL + ALT + T", "Terminal", { omarchy = "terminal" })

-- Vim-style window focus with HYPER + h/j/k/l.
-- Falls back to next/previous workspace when no window in that direction.
local function focus_or_workspace(direction)
  local before = hl.get_active_window()
  local before_address = before and before.address
  hl.dispatch(hl.dsp.focus({ direction = direction }))
  local after = hl.get_active_window()
  local after_address = after and after.address
  if before_address == after_address then
    local fallback = (direction == "l" or direction == "u") and "e-1" or "e+1"
    hl.dispatch(hl.dsp.focus({ workspace = fallback }))
  end
end

o.bind("SUPER + CTRL + ALT + H", "Focus left, or previous workspace", function() focus_or_workspace("l") end)
o.bind("SUPER + CTRL + ALT + J", "Focus down, or next workspace", function() focus_or_workspace("d") end)
o.bind("SUPER + CTRL + ALT + K", "Focus up, or previous workspace", function() focus_or_workspace("u") end)
o.bind("SUPER + CTRL + ALT + L", "Focus right, or next workspace", function() focus_or_workspace("r") end)

-- fullscreen and floating
o.bind("SUPER + CTRL + ALT + F", "Toggle window floating/pinned", "omarchy-hyprland-window-pop")
o.bind("SUPER + CTRL + ALT + SHIFT + F", "Zoom window to edges", hl.dsp.window.fullscreen({ mode = "maximized" }))
-- o.bind("SUPER + CTRL + ALT + SHIFT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Toggle workspace layout (dwindle <-> scrolling) with HYPER+S.
o.bind("SUPER + CTRL + ALT + S", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- Pseudo window: HYPER+P (replaces SUPER+P).
hl.unbind("SUPER + P")  -- was: Pseudo window
o.bind("SUPER + CTRL + ALT + P", "Pseudo window", hl.dsp.window.pseudo())

-- Toggle window split: HYPER+A (replaces SUPER+J).
hl.unbind("SUPER + J")  -- was: Toggle window split
o.bind("SUPER + CTRL + ALT + A", "Toggle window split", hl.dsp.layout("togglesplit"))

-- Switch workspaces with HYPER + 1-10.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("SUPER + CTRL + ALT + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
end

-- Move window to workspace with HYPER+SHIFT+1-10.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("SUPER + CTRL + ALT + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

-- Move windows with HYPER + SHIFT + h/j/k/l.
o.bind("SUPER + CTRL + ALT + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + CTRL + ALT + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + CTRL + ALT + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + CTRL + ALT + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))

-- Window overview: HYPER+O.
-- hyprview doesn't build on Hyprland 0.56.2 yet; binding is inert until then.
o.bind("SUPER + CTRL + ALT + O", "Window overview", "hyprctl dispatch hyprview:toggle")

-- Screenshots: SUPER+SHIFT+3 fullscreen, SUPER+SHIFT+4 area.
hl.unbind("SUPER + SHIFT + code:12")  -- was: Move window to workspace 3
hl.unbind("SUPER + SHIFT + code:13")  -- was: Move window to workspace 4
o.bind("SUPER + SHIFT + code:12", "Fullscreen screenshot", "omarchy-capture-screenshot fullscreen save")
o.bind("SUPER + SHIFT + code:13", "Area screenshot", "omarchy-capture-screenshot region")
