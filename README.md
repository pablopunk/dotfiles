# dotfiles

<img
  src="https://github.com/pablopunk/dotfiles/assets/4324982/d5badddc-5bc7-48dc-aaa4-061d4755826b"
  alt="neovim"
  width="700px" />

## 🚀 Install (nix)

I usually keep the repo in `~/.dotfiles`:

```bash
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

Install with nix:

```bash
nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/.config/nix#m1pro
```

> NOTE: m1pro in this case is one of the possible values. Check nix/hosts for other possible values.

To rebuild the config:

```bash
darwin-rebuild switch --flake ~/.dotfiles/nix#m1pro
```
