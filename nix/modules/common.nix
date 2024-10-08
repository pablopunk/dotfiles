{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowBroken = true; # zed-editor available as unstable
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [ pkgs.mkalias ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Import yabai configuration
  services.yabai = import ./yabai/yabai.nix { inherit pkgs; };
  services.skhd = import ./skhd/skhd.nix { inherit pkgs; };

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  programs.zsh.enable = true;

  system.stateVersion = 5;
}
