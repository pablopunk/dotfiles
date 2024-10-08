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
    pkgs.gh
    pkgs.git
    pkgs.karabiner-elements
    pkgs.mise
    pkgs.powerline-fonts
    pkgs.ripgrep
    pkgs.skhd
    pkgs.starship
    pkgs.tmux
    pkgs.wezterm
    pkgs.yabai
  ];

  imports = [
    ../modules/wezterm/wezterm.nix
    ../modules/zsh/zsh.nix
    ../modules/neovim/neovim.nix
    ../modules/starship/starship.nix
    ../modules/shell.nix
    ../modules/binaries/binaries.nix
  ];
}
