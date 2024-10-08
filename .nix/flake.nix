{
  description = "Pablopunk's Darwin system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
 };
 outputs = inputs@{ self, nixpkgs, nix-darwin, nix-homebrew, home-manager }:
  let
    configuration = { pkgs, config, ... }: {
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs._1password
          pkgs.btop
          pkgs.delta
          pkgs.eza
          pkgs.gh
          pkgs.git
          pkgs.jq
          pkgs.karabiner-elements
          pkgs.luarocks
          pkgs.mise
          pkgs.mkalias # fix for macOS /Applications links
          pkgs.neovim
          pkgs.powerline-fonts
          pkgs.python3
          pkgs.ripgrep
          pkgs.skhd
          pkgs.starship
          pkgs.tmux
          pkgs.vim
          pkgs.wezterm
          pkgs.yabai
          pkgs.zoxide
        ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      homebrew = {
        enable = true;
        casks = [
          "alt-tab"
          "arc"
          "aws-vault"
          "cleanshot"
          "cloudflare-warp"
          "hiddenbar"
          "iina"
          "karabiner-elements"
          "latest"
          "missive"
          "monitorcontrol"
          "notion-calendar"
          "orbstack"
          "raycast"
          "scroll-reverser"
          "sf-symbols"
          "slack"
          "spotify"
          "telegram-desktop"
          "whatsapp"
          "zed"
          "zoom"
        ];
        onActivation.cleanup = "zap"; # remove brew packages that are not in nix
        # onActivation.autoUpdate = true;
        # onActivation.upgrade = true;
      };

      # macOS settings https://mynixos.com/nix-darwin/options/system.defaults
      system.defaults = {
        dock.autohide = true;
        dock.orientation = "right";
        dock.autohide-delay = 0.0;
        dock.persistent-apps = [
          "/Applications/Notion Calendar.app"
          "/Applications/Arc.app"
          "/Applications/Slack.app"
          "/Applications/Cursor.app"
          "${pkgs.wezterm}/Applications/Wezterm.app"
          "/Applications/zoom.us.app"
          "/Applications/Spotify.app"
        ];
        trackpad.Clicking = true;
        trackpad.Dragging = true;
        finder.ShowPathbar = true;
        finder.ShowStatusBar = true;
        NSGlobalDomain.AppleInterfaceStyle = "Dark";
        NSGlobalDomain.KeyRepeat = 2;
      };

      # Fix for /Applications links on macOS.
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
            '';

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Home Manager configuration
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.pablopunk = import ./home-manager/pablopunk.nix;
      };
      # prevents bug https://github.com/nix-community/home-manager/issues/4026
      users.users.pablopunk.home = "/Users/pablopunk";

      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = "pablopunk";
        autoMigrate = false;
      };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#m1pro
    darwinConfigurations."m1pro" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."m1pro".pkgs;
  };
}
