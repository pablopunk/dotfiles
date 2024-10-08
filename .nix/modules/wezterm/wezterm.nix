{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ wezterm ];
  home.file.".wezterm.lua".source = ./wezterm.lua;
}
