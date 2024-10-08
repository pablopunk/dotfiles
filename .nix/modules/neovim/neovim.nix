{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    luarocks
    python3
  ];
  home.file.".config/nvim/init.lua".text = builtins.readFile ./init.lua;
}
