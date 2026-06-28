# Niri on CachyOS

## Design decisions
- **Hyper** (Ctrl+Alt+Super, no Shift) is the sole modifier for niri. `Mod` is not used. Caps Lock → Hyper via xremap.
- Hyper = navigation. Hyper+Shift = moving. This is a hard convention — if a bind needs Shift, it's a "move" action.
- Workspace volume keys and media keys go through noctalia IPC, not raw wpctl/playerctl. Keeps the bar in sync.
- Noctalia handles bar + wallpaper. Therefore `background-color "transparent"` is required in layout.
- `prefer-no-csd` is on. Windows drop their own decorations; niri draws borders.

## Workspaces
- Vertical, per monitor, infinite downward. `empty-workspace-above-first` is enabled so there's always one above.
- **⚠️ Beware:** this reserves workspace index 1 as a permanent empty buffer. All your real workspaces start at index 2. niri silently redirects `move-to-workspace 1` to 2. `Hyper+2` = your first workspace.
- New workspaces spawn at the bottom when you focus past the last one.
- Workspace IDs ≠ workspace indices. `niri msg focused-window` shows IDs; `focus-workspace N` uses indices.

## Config
- KDL syntax. Live-reloads. Validate with `niri validate`. **NEVER** test by sending destructive actions (`quit`, `power-off-monitors`, etc.) to a live niri session — they will kill the compositor and drop the user's desktop.

## Push-to-talk dictation
- True hold-to-talk via xremap (press Insert → record, release → transcribe + type via wtype).
- Requires `input` group membership (`sudo usermod -aG input $USER`, relog).
- Config: `~/.config/xremap/config.yml` maps `Insert` press/release to `nerd-dictation begin`/`end`.
- Service: `systemctl --user enable --now xremap.service` after relog.
- Fallback: niri binds `Hyper+D` (start, auto-end after 2s silence) and `Hyper+Shift+D` (end).
- Toggle options are flags (just write the name), not key=value.
- `spawn-at-startup` top-level nodes must not be indented.
- Sections cannot be repeated unless they configure different named resources (e.g. `output "DP-1"`, `output "HDMI-1"`).

## Gotchas
- `default-opacity` is not a valid niri option. Transparency goes in `window-rule { opacity X; }`.
- X11 apps need `xwayland-satellite`, not `xwayland`.
- No scratchpad, no 2D workspace grid, no window swallowing.
- `background-color "transparent"` without noctalia running = no wallpaper (black screen).
- If noctalia fails to start, there's no bar, no wallpaper, no launcher. Everything looks broken.
- **Vertical stack ("split"):** niri has no split command like grid WMs. To stack windows vertically in one column, pull the neighboring window in with `Hyper+Comma`. To expel the bottom one out, `Hyper+Period`. `Hyper+BracketLeft`/`BracketRight` expels/consumes between adjacent columns.

- **mise Python vs AUR:** `python3` is mise-managed (3.12), but AUR Python packages (e.g. `python-vosk`) install to system Python (3.14). After `paru -S python-*`, always verify the import works with `python3 -c "import <module>"`. If it fails, install via `pip3 install <module>` for the mise Python.
