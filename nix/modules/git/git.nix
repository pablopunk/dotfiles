{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    delta
  ];
  home.file.".gitconfig".source = ./gitconfig;
}
