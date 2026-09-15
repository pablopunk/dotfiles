# Noctalia (v5+ standalone binary, TOML)

## What it is
Desktop shell: bar, launcher, lock screen, clipboard, notifications, settings.
Runs as the `noctalia` binary (autostarted by the compositor, e.g. umbriel).
Without it, the compositor looks broken — no bar, no wallpaper, nothing.

## Two config layers (v5)
1. Hand-written base: `~/.config/noctalia/*.toml` — curated, versioned in dotfiles
   as `config/noctalia/config.toml`. Every `*.toml` in the folder loads
   alphabetically; use `[include]` for subdirs/load-order control.
2. GUI overrides: `~/.local/state/noctalia/settings.toml` — written by the
   Settings UI, wins over the base layer. Versioned in dotfiles as
   `config/noctalia/state/settings.toml` (symlink; Noctalia writes through
   symlinks and keeps them). Lives in a subdir so Noctalia doesn't autoload
   it as base config (only root `*.toml` load automatically). Starts minimal; redundant keys are pruned by
   Noctalia when they match the base layer.

## Commands
```
noctalia config export        # merged user config (for dotfiles curation)
noctalia config export full   # + built-in defaults (inspection only)
noctalia config validate      # check merged config; also `validate <dir|file>`
noctalia msg <command>        # IPC (panel-toggle, volume-up, session lock, ...)
```

## IPC from compositor
Keybindings live in the compositor config (e.g. `config/umbriel/config.toml`)
and call `noctalia msg ...`, e.g. `noctalia msg panel-toggle launcher`.

## Wallpaper
Set via `[wallpaper]` (`directory`, per-monitor `path`). Points at
`~/.dotfiles/config/wallpapers` in this repo.

## Plugins
Managed via Settings UI / new plugin system (`[plugins] enabled` in TOML).
Local plugins: `~/.local/share/noctalia/plugins/`. Do NOT use the old
Quickshell-era `plugins/*.qml` layout (removed 2026-09).
