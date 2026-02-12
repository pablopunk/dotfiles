# Agents Guide for this Dotfiles Repository

This repository is managed with **[dot](https://github.com/pablopunk/dot)** — a zero-dependency, single-binary dotfiles manager. This guide explains the structure, conventions, and recommended workflows.

## For Agentic Coding Agents

### Build/Test/Lint Commands

This is a **dotfiles configuration repository** - there are no traditional build/test/lint processes. Instead:

**Primary Commands:**
```bash
# Preview changes (equivalent to dry-run/build check)
dot --dry-run [profile]           # Preview default or specific profile
dot --dry-run -v [profile]        # Verbose preview

# Apply configurations (equivalent to build/deploy)
dot [profile]                     # Install/link configurations

# Validation commands
dot --profiles                    # List profiles (validates YAML syntax)
dot --defaults-export             # Export macOS system preferences
dot --defaults-import             # Import macOS system preferences

# Testing specific configurations
./benchmark-zsh.sh                # Test ZSH startup performance
source ~/.zshrc                   # Test shell configuration changes
```

**Single "Test" Execution:** For config changes, test individually:
```bash
# Test a specific component
dot --dry-run -v [profile] | grep "component_name"  # Preview single component
~/.bin/script_name                # Test helper binaries directly
zsh -i -c "function_name"         # Test ZSH functions
nvim --version                    # Verify editor config loads
```

### Code Style Guidelines

**File Organization:**
- All configs in `config/` subdirectories by application
- Helper scripts in `config/binaries/` (executable, with shebang)
- Main orchestration in `dot.yaml` (single source of truth)

**Naming Conventions:**
- **Files:** kebab-case for scripts, lowercase for configs (`gitconfig`, `tmux.conf`)
- **Directories:** lowercase, descriptive (`neovim`, `zsh`, `binaries`)
- **Functions:** snake_case in shell scripts
- **Variables:** lowercase in shell, UPPERCASE for env vars

**Shell Script Style:**
```bash
#!/usr/bin/env bash  # or #!/bin/bash
# Use double quotes for variables: "$var"
# Use arrays for multiple values: files=("a" "b")
# Error handling: set -euo pipefail (when appropriate)
# Color output: ANSI escape codes for user feedback
```

**YAML Structure (`dot.yaml`):**
```yaml
profiles:
  "*":                    # Always installed on every machine
    - app_name
    - another_app

  work:                   # Only on your work computer
    - slack
    - docker

config:
  app_name:
    os: ["mac"]           # Platform restrictions (optional)
    install:
      brew: "brew install pkg"
      apt: "sudo apt install -y pkg"
    link:
      "./config/path": "~/target"
    postinstall: |        # Multi-line commands
      command1
      command2
    postlink: "single command"
```

**Import/Path Conventions:**
- Use `~` for home directory references in `dot.yaml`
- Relative paths from repo root: `"./config/app/file"`
- No hardcoded absolute paths in configurations

**Error Handling:**
- Shell scripts: Check command existence with `command -v`
- Provide helpful error messages with color coding
- Graceful degradation (fallback when tools missing)
- Use `|| true` to ignore acceptable failures

**Types and Validation:**
- YAML syntax validated by `dot --profiles`
- Shell scripts: Use ShellCheck-compatible practices
- Lua configs: Follow Neovim conventions (2-space indents)
- Comments: Use vim modelines for file type hints

**Documentation Standards:**
- Inline comments for non-obvious configuration choices
- Multi-line commands should be documented
- Update `AGENTS.md` when conventions change
- Keep README.md focused on quick setup

## TL;DR - Quick Commands

```bash
dot                           # Install default "*" profile (runs on all machines)
dot --dry-run                 # Preview changes without applying
dot --profiles                # List all available profiles
dot work                      # Install "*" profile + "work" profile
dot work laptop               # Install "*" + "work" + "laptop" profiles
dot work git                  # Install "*" + "work" + any tool matching "git"
dot -v --dry-run work         # Verbose preview
dot --dry-run -v              # Verbose dry-run of default profile
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

Profiles are simple lists of tool names defined in the `profiles` section. Each tool has its configuration in the `config` section.

### `"*"` Profile (Always Installs)

Contains tools and configs needed on **every machine**:
- **CLI tools**: git, zsh, tmux, vim, neovim, mise, etc.
- **Cross-platform apps**: ghostty (terminal), editors
- **Essential configs**: gitconfig, shell aliases, keybindings, wallpapers

### Named Profiles (Machine-Specific)

- **`work`**: Tools for work machines (slack, zoom, cloudflare-warp, docker, etc.)
- **`rice`**: Linux desktop environment tools (hyprland, waybar, xremap, etc.)
- Add more profiles as needed for other machine types (e.g., `laptop`, `server`, etc.)

### Nested Profiles (Profile References)

Profiles can reference other profiles to avoid duplication:
```yaml
profiles:
  shells:      # Grouping profile
    - bash
    - zsh
    - fish
  
  work:        # References another profile
    - shells
    - docker
    - slack
```

### How to Use

```bash
dot              # Install all tools from "*" profile
dot work         # Install "*" profile + "work" profile (cumulative)
dot work laptop  # Install "*" + "work" + "laptop" profiles (all combined)
dot work git     # Install "*" + "work" profiles, plus any tool matching "git"
```

## Common Operations

### Testing Changes

**Always run a dry-run to preview changes:**
```bash
dot --dry-run             # Preview default profile
dot --dry-run work        # Preview with work profile
dot --dry-run -v work     # Verbose (show each step)
```

**Testing by Config Type:**
- **Shell configs:** `source ~/.zshrc` or open new terminal
- **Editors:** Restart editor or use reload command (`:e` in Vim)
- **Window managers:** Restart or use reload hotkey (Super+Shift+E for Hyprland)
- **Binaries:** Test with `~/.bin/script_name` after linking

### Adding Tools/Components

1. Create `config/myapp/` with config files
2. Add the tool name to a profile in `dot.yaml`:
   ```yaml
   profiles:
     "*":
       - myapp
   ```
3. Define the tool's configuration in the `config` section:
   ```yaml
   config:
     myapp:
       install:
         brew: "brew install myapp"
         apt: "sudo apt install -y myapp"
       link:
         "./config/myapp/myapprc": "~/.myapprc"
       postinstall: "myapp --setup"
   ```
4. Run `dot --dry-run` to verify, then `dot` to apply

### Commit Style

- Keep commits small and focused (single app/config change)
- Message format: `feat(app): description` or `fix(app): description`
- Examples: `feat(neovim): add LSP config for Go`, `fix(zsh): update PATH order`
- Explain the *why*, not just the *what*

## Git Workflow

- **Use branches**: Create feature branches per change (e.g., `feat/tmux-config`)
- **Avoid large commits**: Don't mix unrelated config files
- **Check for secrets**: Use `git diff` before committing. Never commit API keys, tokens, or SSH keys
- **Use PRs** for non-trivial changes or when collaborating

## Troubleshooting

### Component won't install
- **Check the install command**: `dot --dry-run -v [profile]` shows exact commands that will run
- **Test manually**: Run the install command in your terminal to see actual errors
- **Verify syntax**: Ensure the component is spelled correctly in `dot.yaml` and YAML is valid

### Symlinks not created
- **Check paths**: Use `~` or env vars in `dot.yaml`, not absolute paths
- **Parent directories**: Ensure target directories exist (e.g., `~/.config/` must exist)
- **Conflicts**: Check for existing files at the target path that would block symlink creation
- **Debug**: `ls -la ~/.config/app` to verify link was created correctly

### Config changes don't take effect
- **Shell configs**: Run `source ~/.zshrc` or open a new terminal
- **Apps**: Restart the application (may need to force-quit on macOS)
- **System preferences**: Some changes require logout/login or full restart
- **Hooks**: Check `postlink` hooks are running; manually run with `dot --postlink -v`

### State out of sync
- **Reset state**: Delete `~/.local/state/dot/lock.yaml` and run `dot` again
- **Preview**: Always use `dot --dry-run` before applying if uncertain
- **Rollback**: 
  ```bash
  git checkout -- config/     # Revert config files
  git checkout -- dot.yaml    # Revert dot.yaml
  dot                          # Re-apply
  ```

## Resources

- **[dot GitHub repo](https://github.com/pablopunk/dot)**: Full documentation, examples, and source code
- **`dot --help`**: Built-in help and command reference
- **`dot --profiles`**: List all available profiles in your `dot.yaml`

---

Keep this file updated as the repo structure or `dot` usage conventions evolve.