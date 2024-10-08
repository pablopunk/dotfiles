{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ zsh zsh-autosuggestions zsh-syntax-highlighting ];
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true; # is this working?
  };
  home.file.".zshrc".source = ./zshrc;
}
