# dotfiles

I usually keep the repo in `~/.dotfiles`:

```shell
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

You can link all dotfiles at once:

```shell
bash link.sh
```

The first time you clone the repo, you should install all dependencies:

```shell
bash bootsrap.sh
```

## Add a new dotfile

### Example: `~/.vimrc`

```bash
cd ~/.dotfiles
mkdir vim
mv ~/.vimrc vim/.vimrc
bash link.sh
```
### Example: `~/.config/mise`

```bash
cd ~/.dotfiles
mkdir -p mise/.config/mise
mv ~/.config/mise/* mise/.config/mise/
bash link.sh
```
