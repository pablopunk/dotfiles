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
    (mod "wezterm/wezterm")
    (mod "zsh/zsh")
    (mod "neovim/neovim")
    (mod "starship/starship")
    (mod "shell")
    (mod "binaries/binaries")
    (mod "gh/gh")
    (mod "karabiner/karabiner")
    (mod "tmux/tmux")
    (mod "git/git")
    (mod "vim/vim")
    (mod "zed/zed")
  ];
}
