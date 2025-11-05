# Agents Guide for this Dotfiles Repository

This repository is managed with **[dot](https://github.com/pablopunk/dot)** — a zero-dependency, single-binary dotfiles manager. This guide explains the structure, conventions, and recommended workflows.

## TL;DR - Quick Commands

```bash
dot                    # Install default "*" profile (runs on all machines)
dot --dry-run          # Preview changes without applying
dot --profiles         # List all available profiles
dot work               # Install a specific profile
dot -v --dry-run work  # Verbose preview
```

## Purpose

- **Overview:** This repo stores application configurations, preferences, helper binaries, and macOS defaults managed via `dot.yaml`.
- **Goal:** Make dotfiles installations reproducible, idempotent, and auditable across machines.

## Repository Structure

- **`config/`**: Application-specific configuration folders (e.g., `neovim/`, `zsh/`, `tmux/`, `waybar/`).
- **`config/binaries/`**: Small helper executables (e.g., `compress`, `gck`, `tt`, `tx`). These are symlinked to `~/.bin` and added to `PATH`.
- **`config/wallpapers/`**: Static image files used by desktop environments.
- **`dot.yaml`**: Main configuration file defining profiles, components, links, installs, and macOS defaults. This is the source of truth.
- **Top-level files**: `README.md`, `.luarc.json`, `.gitignore`, and other global manifests.

## Profile Strategy

### `"*"` Profile (Always Installs)

Contains tools and configs needed on **every machine**:
- **CLI tools**: Git, Zsh, Tmux, Vim, Neovim, Mise, etc.
- **Cross-platform apps**: Ghostty (terminal), editors
- **Essential configs**: Gitconfig, shell aliases, keybindings, wallpapers

### Named Profiles (Machine-Specific)

- **`work`**: Tools for work machines (Slack, Zoom, Cloudflare Warp, etc.)
- Add more profiles as needed for other machine types (e.g., `laptop`, `server`, etc.)

### How to Use

```bash
dot              # Install all tools from "*" profile
dot work         # Install "*" profile + "work" profile (cumulative)
dot work laptop  # Install "*" + "work" + "laptop" profiles
```

## First Time Setup

### On a New Machine

1. **Clone this repo**:
   ```bash
   git clone https://github.com/pablopunk/dot ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Install `dot` binary** (if not already installed):
   ```bash
   curl -fsSL https://raw.githubusercontent.com/pablopunk/dot/main/scripts/install.sh | bash
   ```

3. **Preview what will be installed**:
   ```bash
   dot --dry-run          # Default "*" profile only
   dot --dry-run work     # If this is a work machine
   ```

4. **Apply the configuration**:
   ```bash
   dot              # Install defaults
   dot work         # Or include work profile if applicable
   ```

5. **Verify state**:
   ```bash
   echo $PATH       # Should include ~/.bin
   git config user.name  # Should be set
   zsh --version    # Should be the new default shell
   ```

### Platform Notes

- **macOS**: Installs via Homebrew. Some apps (Cursor, Zed, Karabiner, Aerospace) are macOS-only and skip on Linux.
- **Linux**: Uses DNF/APT package managers. GUI apps are replaced with Linux equivalents (e.g., Hyprland + Waybar instead of Aerospace).
- `dot` automatically detects OS and runs the appropriate install command.

## Editing Configurations

### Adding or Modifying Components

1. **Edit the config files**: Place application configs in the appropriate `config/` subfolder (e.g., `config/neovim/init.lua`).
2. **Update `dot.yaml`**: Add or modify the component entry to link files and define install commands.
3. **Test**: Run `dot --dry-run [profile]` to preview changes.
4. **Apply**: Run `dot` (or `dot [profile]`) to install/link.

### YAML Structure

All components live under `profiles.<profile_name>.<component_name>`:

```yaml
profiles:
  "*":  # Always install
    cli:
      git:
        install:
          brew: "brew install git"
          apt: "sudo apt install -y git"
        link:
          "./config/git/gitconfig": "~/.gitconfig"
        postinstall: "git config --global user.name 'Your Name'"
  
  work:  # Only when explicitly requested
    slack:
      os: ["mac"]  # macOS only
      install:
        brew: "brew install slack"
```

**Key fields**:
- `install`: Map of package manager → command (e.g., `brew`, `apt`, `dnf`, `curl`, `cargo`).
- `link`: Map of repo path → home path. Uses `~` for home directory.
- `postinstall`: Shell commands to run after successful installation.
- `postlink`: Shell commands to run after successful linking.
- `os`: Array of OS restrictions (`["mac"]` or `["linux"]`). Omit to run on all platforms.
- `defaults`: (macOS only) Map of domain → plist file for system preferences.

### Commit Style

- Keep commits small and focused (single app/config change).
- Message format: `feat(app): description` or `fix(app): description`.
- Examples: `feat(neovim): add LSP config for Go`, `fix(zsh): update PATH order`, `feat(dot.yaml): add work profile component`.
- Explain the *why*, not just the *what*.

## Testing Changes

### Before Applying

**Always run a dry-run to preview changes**:
```bash
dot --dry-run             # Preview default profile
dot --dry-run work        # Preview with work profile
dot --dry-run -v work     # Verbose (show each step)
```

### Testing by Config Type

Different config types require different reload strategies:

**Shell configs** (`.bashrc`, `.zshrc`, `.zshrc.d/*`):
```bash
# After linking, reload the shell:
source ~/.zshrc
# Or open a new terminal
```

**Editors** (Neovim, Vim, Zed, Cursor):
```bash
# Restart the editor
# Or use editor reload command (e.g., `:e` in Vim to reload buffer)
```

**Window managers / Desktop environment** (Hyprland, Aerospace, Waybar):
```bash
# Full restart or reload hotkey:
# Hyprland: Super+Shift+E
# Aerospace: Check ~/.config/aerospace/aerospace.toml for reload key
```

**Terminal** (Ghostty):
```bash
# Restart terminal application
```

**System preferences** (Dock, Finder, Ice, Mos):
```bash
# Changes take effect after linking
# Some may require app restart or logout/login
```

**Binaries** (`config/binaries/*`):
```bash
# After linking to ~/.bin, they're available in new shell sessions
# Test with: ~/.bin/script_name
```

### Validate Config Syntax

```bash
dot --profiles   # Lists available profiles; errors if YAML is malformed
```

### Incremental Updates

`dot` tracks state in `~/.local/state/dot/lock.yaml`. You only reinstall/relink what's changed:

```bash
dot   # First run: installs everything
dot   # Second run: only updates changed configs (idempotent)
```

## Common Tasks

### Add a New App Config

1. Create `config/myapp/` with the app's config files.
2. Add an entry to `dot.yaml`:
   ```yaml
   profiles:
     "*":
       myapp:
         install:
           brew: "brew install myapp"
           apt: "sudo apt install -y myapp"
         link:
           "./config/myapp/config": "~/.config/myapp"
         postinstall: "myapp --setup"
   ```
3. Run `dot --dry-run` to verify, then `dot` to apply.

### Add a Post-Install Hook

```yaml
profiles:
  "*":
    tmux:
      install:
        brew: "brew install tmux"
      postinstall: |
        echo "Setting up tmux..."
        tmux new-session -d -s default
```

Run independently: `dot --postinstall`

### Add a Post-Link Hook

Useful for triggering app initialization after configs are linked:

```yaml
profiles:
  "*":
    wallpapers:
      link:
        "./config/wallpapers": "~/.config/wallpapers"
      postlink: |
        if [[ $(uname -s) == "Darwin" ]]; then
          osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"${HOME}/.config/wallpapers/image.jpg\""
        fi
```

### Add Platform-Specific Components

Use `os` to restrict components to macOS or Linux:

```yaml
profiles:
  "*":
    aerospace:
      os: ["mac"]  # macOS only
      install:
        brew: "brew install aerospace"
      link:
        "./config/aerospace/aerospace.toml": "~/.config/aerospace/aerospace.toml"
    
    hyprland:
      os: ["linux"]  # Linux only
      install:
        dnf: "sudo dnf install -y hyprland"
      link:
        "./config/hypr": "~/.config/hypr"
```

### Export/Import macOS Defaults

Store system preferences (Dock, Finder, etc.) as plist files:

```yaml
profiles:
  "*":
    dock:
      defaults:
        "com.apple.dock": "./config/macos/dock.plist"
```

Commands:
```bash
dot --defaults-export   # Export current settings to plist files
dot --defaults-import   # Import settings from plist files
```

## Git Workflow

- **Use branches**: Create feature branches per change (e.g., `feat/tmux-config`, `fix/zsh-prompt`).
- **Avoid large commits**: Don't mix unrelated config files.
- **Check for secrets**: Use `git diff` before committing. Never commit API keys, tokens, or SSH keys.
- **Use PRs** for non-trivial changes or when collaborating.

## State Management

`dot` maintains `~/.local/state/dot/lock.yaml` to track:
- Active profiles
- Installed components and their package managers
- Link mappings
- Hook execution status

This enables incremental updates and automatic cleanup of removed components. **Don't manually edit this file.**

## Binaries

Helper scripts in `config/binaries/` should:
- Have a `#!/bin/bash` or `#!/usr/bin/env python` shebang.
- Be marked executable: `chmod +x config/binaries/scriptname`.
- Be linked to `~/.bin` via `dot.yaml`:
  ```yaml
  profiles:
    "*":
      binaries:
        link:
          "./config/binaries": "~/.bin"
  ```
- Test with: `~/.bin/scriptname` or just `scriptname` if `~/.bin` is on `PATH`.

## Security & Secrets

- **Never commit secrets**: Keep API keys, SSH keys, and credentials out of the repo.
- **Audit before pushing**: Run `git diff --cached` to verify no sensitive data is staged.
- **If accidentally committed**: Revoke the credential immediately and clean history.
- **Tip**: Add machine-specific or sensitive files to `.gitignore` and load them separately (e.g., `~/.zshrc.d/secrets.sh`).

## Documentation

- Keep this file (`AGENTS.md`) updated as repo structure or conventions change.
- Add inline comments in `dot.yaml` for non-obvious choices or multi-line install commands.
- Update the main `README.md` with essential setup steps for new users.

## Troubleshooting

### Component won't install
- **Check the install command**: `dot --dry-run -v [profile]` shows exact commands that will run.
- **Test manually**: Run the install command in your terminal to see actual errors.
- **Verify syntax**: Ensure the component is spelled correctly in `dot.yaml` and YAML is valid.

### Symlinks not created
- **Check paths**: Use `~` or env vars in `dot.yaml`, not absolute paths.
- **Parent directories**: Ensure target directories exist (e.g., `~/.config/` must exist).
- **Conflicts**: Check for existing files at the target path that would block symlink creation.
- **Debug**: `ls -la ~/.config/app` to verify link was created correctly.

### Config changes don't take effect
- **Shell configs**: Run `source ~/.zshrc` or open a new terminal.
- **Apps**: Restart the application (may need to force-quit on macOS).
- **System preferences**: Some changes require logout/login or full restart.
- **Hooks**: Check `postlink` hooks are running; manually run with `dot --postlink -v`.

### State out of sync
- **Reset state**: Delete `~/.local/state/dot/lock.yaml` and run `dot` again.
- **Preview**: Always use `dot --dry-run` before applying if uncertain.
- **Rollback**: 
  ```bash
  git checkout -- config/     # Revert config files
  git checkout -- dot.yaml    # Revert dot.yaml
  dot                          # Re-apply
  ```

## Resources

- **[dot GitHub repo](https://github.com/pablopunk/dot)**: Full documentation, examples, and source code.
- **`dot --help`**: Built-in help and command reference.
- **`dot --profiles`**: List all available profiles in your `dot.yaml`.

---

Keep this file updated as the repo structure or `dot` usage conventions evolve.
