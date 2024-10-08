{ config, pkgs, ... }:

{
  home.packages = [ pkgs.wezterm ];
  home.file.".wezterm.lua".text = builtins.readFile ./wezterm.lua;
}
