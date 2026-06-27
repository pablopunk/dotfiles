# Noctalia (niri shell)

## What it is
A Quickshell desktop shell that provides bar, wallpaper, launcher, lock screen, clipboard, notifications, settings. Started by niri's autostart. Without it, niri looks broken — no bar, no wallpaper, nothing.

## How it runs
```
spawn-sh-at-startup "qs -c noctalia-shell"
```
Config lives at `/etc/xdg/quickshell/noctalia-shell/`. User config at `~/.config/noctalia/`.

## IPC
Noctalia's keybindings live in niri's `keybinds.kdl`. Noctalia provides IPC targets; niri calls them:
```
qs -c noctalia-shell ipc call <target> <function>
```
List all targets: `qs -c noctalia-shell ipc show`

## Wallpaper
Requires `background-color "transparent"` in niri's layout. Scans `~/Pictures/Wallpapers`. If that dir doesn't exist, wallpaper silently fails and you get whatever's behind niri (usually black). Create the dir and restart noctalia to fix.

## Clipboard
Noctalia has its own clipboard manager. `cliphist` also runs alongside it (via `wl-paste --watch cliphist store`). Both coexist — the launcher opens noctalia's clipboard picker, cliphist records system-level clipboard changes.

## Plugins
132 plugins available from the Noctalia Plugins registry. Managed via noctalia's settings UI, not CLI. Plugin state in `~/.config/noctalia/plugins.json`.
