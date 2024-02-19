# dotfiles

![CleanShot 2024-02-17 at 16 17 32@2x-squashed](https://github.com/pablopunk/dotfiles/assets/4324982/55cf222d-4f13-45f0-8571-22064c71ca0f)

I usually keep the repo in `~/.dotfiles`:

```bash
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

If it's the first time you clone the repo, run bootsrap:

```bash
./bootsrap.sh
```

This will:

* Install all dependencies by calling every `*/bootstrap.sh` file in the repo
* Link all dotfiles by calling `link.sh`

If you only want to link files:

```bash
./link.sh
```

Or just link the one you want:

```bash
./link.sh nvim
```

The first time you clone the repo, you should install all dependencies:

```bash
./bootsrap.sh
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
