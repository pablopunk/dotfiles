{ config, pkgs, ... }:

{
  home.username = "pablopunk";
  home.stateVersion = "24.05";
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  imports = [
    ../modules/wezterm/wezterm.nix
    ../modules/zsh/zsh.nix
  ];
}