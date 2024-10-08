{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    vim
    ripgrep
  ];

  home.file.".vimrc".source = ./vimrc;
}
