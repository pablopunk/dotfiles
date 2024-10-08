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

  imports = let
    mod = path: ../modules + "/${path}.nix";
  in [
    (mod "binaries/binaries")
    (mod "gh/gh")
    (mod "git/git")
    (mod "karabiner/karabiner")
    (mod "neovim/neovim")
    (mod "shell")
    (mod "starship/starship")
    (mod "tmux/tmux")
    (mod "vim/vim")
    (mod "wezterm/wezterm")
    (mod "zed/zed")
    (mod "zsh/zsh")
  ];
}
