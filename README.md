# dotfiles

I usually keep the repo in `~/.dotfiles`:

```bash
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

You can link all dotfiles at once:

```bash
bash link.sh
```

Or just link the one you want:

```bash
bash link.sh nvim
```

The first time you clone the repo, you should install all dependencies:

```bash
bash bootsrap.sh
```

## Add a new config

Specify a name and a path to the config:

```bash
bash add.sh alacritty ~/.config/alacritty
bash add.sh vim ~/.vimrc
```

## Remove a config from the repo

This will move it back to the original location, and remove the symlink:

```bash
bash remove.sh alacritty ~/.config/alacritty
bash remove.sh vim ~/.vimrc
```
