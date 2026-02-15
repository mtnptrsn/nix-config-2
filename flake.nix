{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
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
            ./hosts/${hostName}/hardware-configuration.nix
            ./system
            ./hosts/${hostName}
            home-manager.nixosModules.home-manager
            maccel.nixosModules.default
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";
              home-manager.users.mtnptrsn = {
                imports = [
                  ./home
                  ./hosts/${hostName}/home.nix
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
        work = mkHost "work";
      };
    };
}
