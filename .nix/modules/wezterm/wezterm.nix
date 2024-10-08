{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ wezterm ];
  home.file.".wezterm.lua".text = builtins.readFile ./wezterm.lua;
}
