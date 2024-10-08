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
    mkDarwinConfiguration = { system, hostname, username }: nix-darwin.lib.darwinSystem {
      modules = [
        ./modules/common.nix
        ./hosts/${hostname}.nix
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        {
          nixpkgs.hostPlatform = system;
          users.users.${username}.home = "/Users/${username}";
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = import ./home-manager/${username}.nix;
          };
        }
      ];
    };
  in
  {
    darwinConfigurations = {
      m1pro = mkDarwinConfiguration {
        system = "aarch64-darwin";
        hostname = "m1pro";
        username = "pablopunk";
      };
      m1air = mkDarwinConfiguration {
        system = "aarch64-darwin";
        hostname = "m1air";
        username = "pol";
      };
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."m1pro".pkgs;
  };
}
