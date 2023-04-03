{
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-22.11;
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    fsr-infoscreen.url = github:fsr/infoscreen;
  };
  outputs = { self, nixpkgs, sops-nix, fsr-infoscreen, ... }@inputs:
    let
    in {
      #packages."aarch64-linux".sanddorn = self.nixosConfigurations.sanddorn.config.system.build.sdImage;
      packages."x86_64-linux".quitte = self.nixosConfigurations.quitte-vm.config.system.build.vm;
      packages."x86_64-linux".default = self.packages."x86_64-linux".quitte;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      nixosConfigurations = {
        sanddorn = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            {
              nixpkgs.overlays = [ fsr-infoscreen.overlay."aarch64-linux" ];
              nixpkgs.config.allowBroken = true;
              sdImage.compressImage = false;
            }
            ./hosts/sanddorn/configuration.nix
            ./modules/infoscreen.nix
            ./modules/base.nix
            ./modules/desktop.nix
            ./modules/options.nix
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            {
              fsr.enable_office_bloat = false;
            }
          ];
        };
        quitte = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./hosts/quitte/configuration.nix
            ./modules/options.nix
            ./modules/base.nix
            ./modules/sops.nix
            ./modules/ldap.nix
            # ./modules/keycloak.nix replaced by portunus
            ./modules/mail.nix
            ./modules/nginx.nix
            ./modules/hedgedoc.nix
            ./modules/wiki.nix
            ./modules/ftp.nix
            ./modules/stream.nix
            ./modules/nextcloud.nix
            ./modules/matrix.nix
            ./modules/sogo.nix
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
            ./modules/ldap.nix
            # ./modules/keycloak.nix replaced by portunus
            ./modules/nginx.nix
            ./modules/mail.nix
            ./modules/mailman.nix
            ./modules/hedgedoc.nix
            ./modules/wiki.nix
            ./modules/stream.nix
            ./modules/sogo.nix
            ./modules/vm.nix
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
