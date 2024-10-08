{ config, pkgs, ... }:

{
  imports = [ ./common.nix ];
  home.username = "pol";
  home.packages = with pkgs; [
    mise
  ];
}
