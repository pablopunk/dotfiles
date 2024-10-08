{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ gh ];
  home.file.".config/gh/config.yml".source = ./config.yml;
}
