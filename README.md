# dotfiles

> I use neovim BTW. My setup is blazing fast BTW.

![nvim](https://github.com/pablopunk/dotfiles/assets/4324982/fc32e5a7-52f4-4045-b199-4ae1486225d0)

## 🚀 Install

![link](https://github.com/pablopunk/dotfiles/assets/4324982/55cf222d-4f13-45f0-8571-22064c71ca0f)

I usually keep the repo in `~/.dotfiles`:

```bash
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

```bash
./install.sh
```

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
