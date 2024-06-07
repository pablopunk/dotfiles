# dotfiles

<img
  src="https://github.com/pablopunk/dotfiles/assets/4324982/d5badddc-5bc7-48dc-aaa4-061d4755826b"
  alt="neovim"
  width="700px" />

## 🚀 Install

I usually keep the repo in `~/.dotfiles`:

```bash
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

```bash
./install.sh
```

<img
  src="https://github.com/pablopunk/dotfiles/assets/4324982/55cf222d-4f13-45f0-8571-22064c71ca0f"
  alt="link"
  width="80%" />

This will:

* Install all dependencies by calling every `*/bootstrap.sh` file in the repo
* Link all dotfiles (using `stow`)

Or just link the one you want:

```bash
./link.sh nvim
```

## ✅ Add a new config to the repo

Specify a name and a path to the config:

```bash
./add.sh alacritty ~/.config/alacritty
./add.sh vim ~/.vimrc
```

## ❌ Remove a config from the repo

This will move it back to the original location and remove the folder from the repo (be careful if you have a `bootsrap.sh` inside the folder, it will be removed):

```bash
./remove.sh alacritty ~/.config/alacritty
./remove.sh vim ~/.vimrc
```
