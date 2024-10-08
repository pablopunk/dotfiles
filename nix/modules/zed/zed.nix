{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    zed
  ];

  home.file = {
    ".config/zed" = {
      source = ./config;
      recursive = true;
    };
  };
}
