{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    kpp.url = "github:fsr/kpp";
    kpp.inputs.nixpkgs.follows = "nixpkgs";
    print-interface = {
      url = "github:fsr/print-interface";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ese-manual.url = "git+https://git.ifsr.de/ese/manual-website";
    ese-manual.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    notenrechner.url = "git+https://git.ifsr.de/frieder.hannenheim/notenrechner.git";
    notenrechner.inputs.nixpkgs.follows = "nixpkgs";


    course-management = {
      url = "github:fsr/course-management";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { self
    , nixpkgs
    , sops-nix
    , nix-index-database
    , kpp
    , ese-manual
    , vscode-server
    , course-management
    , print-interface
    , ...
    }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});

    in
    {
      packages = forAllSystems (system: rec {
        default = quitte;
        quitte = self.nixosConfigurations.quitte.config.system.build.toplevel;
        tomate = self.nixosConfigurations.tomate.config.system.build.toplevel;
      });
      formatter = forAllSystems (system: pkgs.${system}.nixpkgs-fmt);
      hydraJobs = forAllSystems (system: {
        quitte = self.packages.${system}.quitte;
      });

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShell {
          packages = with pkgs.${system}; [
            sops
          ];
        };
      });
      overlays.default = import ./overlays;
      nixosConfigurations = {
        quitte = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = inputs // { inherit system; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.kpp.nixosModules.default
            inputs.nix-index-database.nixosModules.nix-index
            ese-manual.nixosModules.default
            course-management.nixosModules.default
            vscode-server.nixosModules.default
            ./hosts/quitte/configuration.nix
            ./options

            ./modules/core
            ./modules/ldap
            ./modules/mail
            ./modules/web
            ./modules/courses
            ./modules/wiki
            ./modules/matrix
            ./modules/keycloak
            ./modules/monitoring

            ./modules/nix-serve.nix
            ./modules/hedgedoc.nix
            ./modules/padlist.nix
            ./modules/nextcloud.nix
            ./modules/vaultwarden.nix
            ./modules/forgejo
            ./modules/kanboard.nix
            ./modules/zammad.nix
            # ./modules/decisions.nix
            ./modules/stream.nix
            # ./modules/struktur-bot.nix
            {
              nixpkgs.overlays = [
                self.overlays.default
              ];
              sops.defaultSopsFile = ./secrets/quitte.yaml;
            }
          ];
        };
        tomate = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs;
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.nix-index-database.nixosModules.nix-index
            vscode-server.nixosModules.default
            print-interface.nixosModules.default
            ./hosts/tomate/configuration.nix
            ./modules/core/base.nix
            ./modules/core/zsh.nix
            ./modules/core/sssd.nix
            {
              sops.defaultSopsFile = ./secrets/tomate.yaml;
            }
          ];
        };
      };
    };
}
