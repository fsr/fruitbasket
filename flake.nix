{
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-23.05;
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    kpp.url = "github:fsr/kpp";
    kpp.inputs.nixpkgs.follows = "nixpkgs";
    course-management = {
      url = "github:fsr/course-management";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, sops-nix, kpp, course-management, ... }@inputs:
    {
      packages."x86_64-linux".quitte = self.nixosConfigurations.quitte.config.system.build.toplevel;
      packages."x86_64-linux".default = self.packages."x86_64-linux".quitte;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      hydraJobs."x86-64-linux".quitte = self.packages."x86_64-linux".quitte;

      nixosConfigurations = {
        quitte = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.kpp.nixosModules.default
            course-management.nixosModules.default
            ./hosts/quitte/configuration.nix
            ./modules/bacula.nix
            ./modules/options.nix
            ./modules/base.nix
            ./modules/sops.nix
            ./modules/kpp.nix
            ./modules/ldap
            ./modules/mail
            ./modules/mailman.nix
            ./modules/nginx.nix
            ./modules/hydra.nix
            ./modules/userdir.nix
            ./modules/hedgedoc.nix
            ./modules/padlist.nix
            ./modules/postgres.nix
            ./modules/wiki.nix
            ./modules/ftp.nix
            ./modules/stream.nix
            ./modules/nextcloud.nix
            ./modules/matrix.nix
            ./modules/mautrix-telegram.nix
            ./modules/sogo.nix
            ./modules/vaultwarden.nix
            ./modules/website.nix
            ./modules/zsh.nix
            ./modules/course-management.nix
            ./modules/gitea.nix
            {
              fsr.domain = "staging.ifsr.de";
              sops.defaultSopsFile = ./secrets/quitte.yaml;
            }
          ];
        };
      };
    };
}
