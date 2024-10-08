{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    eza
    jq
    python3
    zoxide
    vim
  ];
}
