{
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-23.05;
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    kpp.url = "github:fsr/kpp";
    kpp.inputs.nixpkgs.follows = "nixpkgs";
    # fsr-infoscreen.url = github:fsr/infoscreen; # some anonymous strukturer accidentally removed the flake.nix
    course-management = {
      url = "github:fsr/course-management";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, sops-nix, kpp, course-management, ... }@inputs:
    {
      packages."x86_64-linux".quitte = self.nixosConfigurations.quitte-vm.config.system.build.vm;
      packages."x86_64-linux".default = self.packages."x86_64-linux".quitte;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

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
            # ./modules/keycloak.nix replaced by portunus
            ./modules/mail.nix
            ./modules/mailman.nix
            ./modules/nginx.nix
            ./modules/userdir.nix
            ./modules/hedgedoc.nix
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
              fsr.enable_office_bloat = false;
              fsr.domain = "staging.ifsr.de";
              sops.defaultSopsFile = ./secrets/quitte.yaml;
            }
          ];
        };
        quitte-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./hosts/quitte/configuration.nix
            ./modules/options.nix
            ./modules/base.nix
            ./modules/ldap
            ./modules/nginx.nix
            ./modules/mail.nix
            ./modules/mailman.nix
            ./modules/hedgedoc.nix
            ./modules/wiki.nix
            ./modules/stream.nix
            ./modules/sogo.nix
            ./modules/vm.nix
            ./modules/website.nix
            "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
            {
              _module.args.buildVM = true;
              sops.defaultSopsFile = ./secrets/test.yaml;
            }
          ];
        };
      };
    };
}
