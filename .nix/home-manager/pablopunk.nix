{ config, pkgs, ... }:

{
  home.username = "pablopunk";
  home.stateVersion = "24.05";
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    pkgs._1password
    pkgs.btop
    pkgs.delta
    pkgs.git
    pkgs.mise
    pkgs.powerline-fonts
    pkgs.ripgrep
    pkgs.skhd
    pkgs.tmux
    pkgs.yabai
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
  ];
}
