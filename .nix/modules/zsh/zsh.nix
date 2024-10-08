{ config, pkgs, ... }:

{
  home.packages = [ pkgs.zsh pkgs.zsh-autosuggestions pkgs.zsh-syntax-highlighting ];
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
  home.file.".zshrc".text = builtins.readFile ./zshrc;
}
