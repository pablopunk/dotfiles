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

### Version matters
- **0.3.x** (old cargo install): no virtual workspaces, no `keycode_for_key_name` three-tier fallback. Static key names like `minus`, `rightbracket`, `leftbracket` silently fail — only dynamic layout-generated characters work.
- **0.4.x** (brew install): has everything. Use `brew install paneru`. If you see `paneru --version` returning 0.3.x, uninstall the cargo version.

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
TOML in `[bindings]` can't have duplicate keys. If you need multiple bindings for one action, use an array:
```toml
# ✅ Correct
window_virtual_south = ["ctrl + alt + cmd - j", "ctrl + alt + cmd - u"]

# ❌ Crashes on reload
window_virtual_south = "ctrl + alt + cmd - j"
window_virtual_south = "ctrl + alt + cmd - u"
```
Paneru will log `TOML parse error at line N` and fall back to the last valid config.

### Focus north/south ≠ workspace switching
`window_focus_north`/`_south` navigates vertical **stacks** within a column, then falls through to **display** switching. It does NOT switch virtual workspaces. For workspace switching, use `window_virtual_north`/`_south`.

### Virtual workspaces are rows
In niri, workspaces stack vertically (infinite downward). In Paneru, they're "virtual workspace rows" within a macOS space:
- `window_virtual_south` / `_north` = switch rows
- `window_virtualmove_south` / `_north` = move window to row
- `window_virtualnum_N` = jump to row N
- `window_virtualmovenum_N` = move window to row N

### Animations
`animation_speed` controls all window movement. Unset = 1,000,000 (instant). Range 8–20 for smooth. There are no spring-based animations — Paneru only does linear speed.

### Active border / dimming
- `[decorations.active.border]` — colored border around focused window. `enabled`, `color`, `width`, `opacity`, `radius`.
- `[decorations.inactive.dim]` — macOS-native dimming on unfocused windows. `opacity` (-1.0 to 1.0), optional `opacity_night` for dark mode. No per-window opacity rules (unlike niri).

### No per-window visual rules
Paneru window rules (`[windows.xxx]`) support: `floating`, `index`, `width`, `grid`, `horizontal_padding`, `vertical_padding`, `dont_focus`, `bindings_passthrough`, `border_radius`. No corner-radius, no opacity, no blur — that's niri-only territory.

### Running as a service
`paneru start` installs a launchd agent but accessibility permissions don't carry over. Run from terminal (`paneru &`) or grant the binary explicit accessibility access.
