{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
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

    course-management = {
      url = "github:fsr/course-management";
      inputs.nixpkgs.follows = "nixpkgs";
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
      formatters = forAllSystems (system: rec {
        default = pkgs.${system}.nixpkgs-fmt;
      });
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
        quitte = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs;
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.kpp.nixosModules.default
            inputs.nix-index-database.nixosModules.nix-index
            ese-manual.nixosModules.default
            course-management.nixosModules.default
            vscode-server.nixosModules.default
            ./hosts/quitte/configuration.nix
            ./modules/bacula.nix
            ./modules/options.nix
            ./modules/base.nix
            ./modules/sops.nix
            ./modules/kpp.nix
            ./modules/ese-website.nix

            ./modules/ldap
            ./modules/sssd.nix
            ./modules/mail
            ./modules/mailman.nix
            ./modules/mysql.nix
            ./modules/nix-serve.nix
            ./modules/nginx.nix
            # ./modules/hydra.nix
            ./modules/userdir.nix
            ./modules/hedgedoc.nix
            ./modules/padlist.nix
            ./modules/postgres.nix
            ./modules/wiki
            ./modules/ftp.nix
            #./modules/stream.nix
            ./modules/nextcloud.nix
            ./modules/matrix.nix
            ./modules/mautrix-telegram.nix
            ./modules/sogo.nix
            ./modules/vaultwarden.nix
            ./modules/website.nix
            ./modules/zsh.nix
            ./modules/course-management.nix
            ./modules/courses-phil.nix
            ./modules/gitea.nix
            ./modules/fail2ban.nix
            ./modules/kanboard.nix
            ./modules/infoscreen.nix
            ./modules/manual.nix
            ./modules/sharepic.nix
            ./modules/zammad.nix
            ./modules/initrd-ssh.nix
            ./modules/fsrewsp.nix
            ./modules/nightline.nix
            ./modules/decisions.nix
            ./modules/struktur-bot.nix
            {
              nixpkgs.overlays = [ self.overlays.default ];
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
            ./modules/base.nix
            ./modules/zsh.nix
            ./modules/fail2ban.nix
            ./modules/sssd.nix
            {
              sops.defaultSopsFile = ./secrets/tomate.yaml;
            }
          ];
        };
      };
    };
}
