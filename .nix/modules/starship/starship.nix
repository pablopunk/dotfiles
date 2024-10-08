{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ starship ];
  home.file.".config/starship.toml".text = builtins.readFile ./starship.toml;
}
