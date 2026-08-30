# Xremap

## modmap vs keymap
- `modmap` remaps keys; `keymap` remaps combos. Remapping a key to modifier keys is only valid in `modmap` — `keymap` handles modifiers differently and cannot emit them.
- A `modmap` remap can emit multiple keys at once (e.g. one key to several modifiers) via a YAML list; `keymap` cannot.
- `keymap` sees the output of `modmap`. A physical key remapped in `modmap` is only matchable in `keymap` by its new keysym, not its original one.
- Modifier-only prefixes like `Ctrl-`/`Super-` match both left and right; `Ctrl_L-`-style prefixes match a specific side.

## Practical
- Unknown key names: run with `RUST_LOG=debug` and press the key; it logs the name.
- `xremap --list-devices` shows grabable devices for `--device`.
- `--watch=device,config` reloads on new devices and config changes.
- Config files are plain YAML lists under `modmap:`/`keymap:`; each entry can take `name`, `application`, `device` filters.

## Service
- Systemd **user** unit, no root needed; linked to `~/.config/systemd/user/xremap.service`.
- Runs the cargo binary (`~/.cargo/bin/xremap`) with `--watch=device,config`.
- Config edits to the repo file reload automatically through the symlink — no restart needed on valid YAML.
- Gotcha: invalid YAML doesn't crash the daemon; the watch reload fails silently (old config stays active, errors land in the journal).
- Deliberate restarts: `systemctl --user restart xremap.service`.
- Don't start a second xremap manually while the unit runs — both grab the keyboard.

## Testing
- Syntax: `ruby -e 'require "yaml"; YAML.load_file("config/xremap/config.yml")'`
- No validate flag — just run `xremap config/xremap/config.yml`; bad configs fail at startup.
- Running xremap manually grabs the keyboard; end the process to restore normal input.
