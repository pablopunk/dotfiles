# Paneru (macOS sliding-tiling WM)

## What it is
A niri-inspired scrollable-tiling window manager for macOS. Windows live on a horizontal strip; each monitor has its own independent strip. Virtual workspaces are "rows" within a macOS space.

## Config
TOML, live-reloads. Default location: `~/.paneru`.
```
./config/paneru/paneru.toml -> ~/.paneru
```

## Keybinding conventions (mapped from niri)
Hyper = **ctrl+alt+cmd** (macOS has no Super key).

| Modifier | Role |
|---|---|
| Hyper | Navigate (focus, switch workspaces) |
| Hyper+Shift | Move (swap windows, move to workspace) |

## Gotchas

### Key names
Paneru uses real key names, not config-friendly aliases:
| You'd expect | Paneru needs |
|---|---|
| `left` / `right` / `up` / `down` | `leftarrow` / `rightarrow` / `uparrow` / `downarrow` |
| `[` / `]` | `leftbracket` / `rightbracket` |
| `-` / `=` | `minus` / `equal` (or the literal char) |
| `,` / `.` | `comma` / `period` (or the literal char) |

Letters and numbers (`h`, `j`, `1`, `9`) work as-is. `home`, `end`, `pageup`, `pagedown`, `delete`, `escape` work as-is.

### Duplicate keys crash the config
TOML in `[bindings]` can't have duplicate keys. Merge into arrays:
```toml
# ✅ Correct
window_virtual_south = ["ctrl + alt + cmd - j", "ctrl + alt + cmd - u"]

# ❌ Silent crash on reload
window_virtual_south = "ctrl + alt + cmd - j"
window_virtual_south = "ctrl + alt + cmd - u"
```

### Focus north/south ≠ workspace switching
`window_focus_north`/`_south` navigates vertical stacks within a column, then falls through to display switching. It does NOT switch virtual workspaces. Use `window_virtual_north`/`_south` for workspace switching.

### Virtual workspaces are rows
In niri, workspaces stack vertically. In Paneru, they're "virtual workspace rows":
- `window_virtual_south` / `_north` = switch rows
- `window_virtualmove_south` / `_north` = move window to row
- `window_virtualnum_N` = jump to row N
- `window_virtualmovenum_N` = move window to row N

### Animations
`animation_speed` controls all window movement. Unset = instant. Range 8–20 for smooth. No spring-based animations — linear speed only.

### Active border / dimming
- `[decorations.active.border]` — colored border around focused window. `enabled`, `color`, `width`, `opacity`, `radius`.
- `[decorations.inactive.dim]` — native macOS dimming on unfocused windows. `opacity` (-1.0 to 1.0), optional `opacity_night` for dark mode.

No per-window opacity, corner-radius, or blur rules (unlike niri's `window-rule`).

### Running as a service
`paneru start` installs a launchd agent but accessibility permissions don't carry over. Run from terminal (`paneru &`) instead.
