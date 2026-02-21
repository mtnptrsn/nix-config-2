{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    maccel.url = "github:Gnarus-G/maccel";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-darwin,
      maccel,
      nixvim,
      ...
    }:
    let
      mkHost =
        hostName:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./system
            ./profiles/${hostName}
            home-manager.nixosModules.home-manager
            maccel.nixosModules.default
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";
              home-manager.users.mtnptrsn = {
                imports = [
                  ./home
                  ./profiles/${hostName}/home.nix
                  nixvim.homeModules.nixvim
                ];
              };
            }
          ];
        };
      mkDarwinHost =
        hostName:
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./darwin
            ./profiles/${hostName}
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";
              home-manager.users.mtnptrsn = {
                imports = [
                  ./home
                  ./profiles/${hostName}/home.nix
                  nixvim.homeModules.nixvim
                ];
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        private = mkHost "private";
      };

      darwinConfigurations = {
        private-macbook = mkDarwinHost "private-macbook";
      };
    };
}
