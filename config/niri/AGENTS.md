# Niri on CachyOS

## Design decisions
- **Hyper** (Ctrl+Alt+Super, no Shift) is the sole modifier for niri. `Mod` is not used. Caps Lock → Hyper via xremap.
- Hyper = navigation. Hyper+Shift = moving. This is a hard convention — if a bind needs Shift, it's a "move" action.
- Workspace volume keys and media keys go through noctalia IPC, not raw wpctl/playerctl. Keeps the bar in sync.
- Noctalia handles bar + wallpaper. Therefore `background-color "transparent"` is required in layout.
- `prefer-no-csd` is on. Windows drop their own decorations; niri draws borders.

## Workspaces
- Vertical, per monitor, infinite downward. `empty-workspace-above-first` is enabled so there's always one above.
- New workspaces spawn at the bottom when you focus past the last one.
- Workspace IDs ≠ workspace indices. `niri msg focused-window` shows IDs; `focus-workspace N` uses indices.

## Config
- KDL syntax. Live-reloads. Validate with `niri validate`.
- Toggle options are flags (just write the name), not key=value.
- `spawn-at-startup` top-level nodes must not be indented.
- Sections cannot be repeated unless they configure different named resources (e.g. `output "DP-1"`, `output "HDMI-1"`).

## Gotchas
- `default-opacity` is not a valid niri option. Transparency goes in `window-rule { opacity X; }`.
- X11 apps need `xwayland-satellite`, not `xwayland`.
- No scratchpad, no 2D workspace grid, no window swallowing.
- `background-color "transparent"` without noctalia running = no wallpaper (black screen).
- If noctalia fails to start, there's no bar, no wallpaper, no launcher. Everything looks broken.
