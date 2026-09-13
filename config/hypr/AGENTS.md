# Hyprland (Omarchy) Configuration

`~/.config/hypr` symlinks to this directory, so edits here are live — no `dot`
run needed. Hyprland auto-reloads on save; after every change, validate:

```bash
hyprctl reload && hyprctl configerrors
```

Before changing these files, load the `omarchy` skill — it covers Hyprland
configuration, but is installed read-only under `/usr/share/omarchy` (report
improvements upstream, don't edit it in place).

## Known gotchas

- **Keysym names must be lower-case** xkbcommon names (`comma`, `period`);
  upper-case spellings like `COMMA` silently do not match.
- **The scrolling layout clamps window resize dispatchers** to the visible
  viewport, so sizing presets creep in increments and never land. For tiled
  windows in that layout (`monitor.active_workspace.tiled_layout == "scrolling"`),
  resize the column instead: `hl.dsp.layout("colresize <fraction>")`, or cycle
  presets defined in `scrolling:explicit_column_widths` (in `looknfeel.lua`)
  with `colresize +conf` / `colresize -conf`.
- **Lua API lookup:** `hl.*` is documented by the stubs at
  `/usr/share/hypr/stubs/hl.meta.lua`; for dispatcher semantics, read the
  Hyprland source at the running tag (`hyprctl version` →
  `raw.githubusercontent.com/hyprwm/Hyprland/v<tag>/src/`).
