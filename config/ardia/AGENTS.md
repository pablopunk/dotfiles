# Ardia configuration

- Ardia applies config changes at launch and on save, but does not write its settings back to the config file. The config CLI does not export existing app settings.
- Use `ardia config list` for available settings, `ardia commands` for shortcut command IDs, and `ardia config set --help` for shortcut syntax.
- Validate changes with `ardia config check` and, for themes, `ardia theme check`. Heed warnings if schema validation is limited.
