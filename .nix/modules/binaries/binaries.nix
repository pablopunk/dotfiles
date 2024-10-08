{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ fzf ];
  home.file.".bin".source = ./bin;
}
