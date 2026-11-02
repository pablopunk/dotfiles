# Ardia configuration

- `config.json` is linked by `dot.toml` to `~/.config/ardia/config.json`. Use `dot --dry-run -l ardia` to preview the link and `dot -l ardia` to install it.
- Ardia reads the JSON at launch and when it changes; it does not write its settings back to the file. The config CLI does not export existing app settings.
- Put settings under `settings` and shortcut bindings under `settings.shortcuts`, keyed by command ID. Use `ardia config list` for supported settings and `ardia commands` for command IDs.
- Shortcut strings use modifiers such as `cmd`, `opt`, `ctrl`, and `shift` joined with `+` and a key. An empty string unbinds a shortcut. See `ardia config set --help` for the full syntax.
- Run `ardia config check` after changes. The CLI uses Ardia's generated schema when available; heed warnings if validation is limited.
- Custom themes live in `~/.config/ardia/themes/<name>.json` and are selected by the top-level `theme` key. See `ardia theme --help` and validate with `ardia theme check`. Theme files are not automatically linked by the config file's link.
