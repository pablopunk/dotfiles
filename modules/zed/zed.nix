{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # build is not working
    # zed-editor
  ];

  home.file = {
    ".config/zed" = {
      source = ./config;
      recursive = true;
    };
  };
}
