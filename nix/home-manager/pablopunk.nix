{ config, pkgs, ... }:

{
  home.username = "pablopunk";
  home.stateVersion = "24.05";
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    _1password
    btop
    delta
    git
    mise
    powerline-fonts
    ripgrep
    skhd
    tmux
    yabai
  ];

  imports = [
    ../modules/wezterm/wezterm.nix
    ../modules/zsh/zsh.nix
    ../modules/neovim/neovim.nix
    ../modules/starship/starship.nix
    ../modules/shell.nix
    ../modules/binaries/binaries.nix
    ../modules/gh/gh.nix
    ../modules/karabiner/karabiner.nix
    ../modules/tmux/tmux.nix
    ../modules/git/git.nix
    ../modules/vim/vim.nix
  ];
}
