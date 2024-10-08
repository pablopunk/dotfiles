{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ karabiner-elements ];
  home.file.".config/karabiner".source = ./config;
}
