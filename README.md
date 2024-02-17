# dotfiles

I usually keep the repo in `~/.dotfiles`:

```bash
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

If it's the first time you clone the repo, run bootsrap:

```bash
bash bootsrap.sh
```

This will:

* Install all dependencies by calling every `*/bootstrap.sh` file in the repo
* Link all dotfiles by calling `link.sh`

If you only want to link files:

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

## ✅ Add a new config to the repo

Specify a name and a path to the config:

```bash
bash add.sh alacritty ~/.config/alacritty
bash add.sh vim ~/.vimrc
```

## ❌ Remove a config from the repo

This will move it back to the original location and remove the folder from the repo (be careful if you have a `bootsrap.sh` inside the folder, it will be removed):

```bash
bash remove.sh alacritty ~/.config/alacritty
bash remove.sh vim ~/.vimrc
```
