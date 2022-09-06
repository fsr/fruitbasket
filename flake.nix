{
  inputs = { 
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    fsr-infoscreen.url = github:fsr/infoscreen;
  };
  outputs = { self, nixpkgs, sops-nix, fsr-infoscreen, ... }@inputs:  
  let 
  in {
    #packages."aarch64-linux".sanddorn = self.nixosConfigurations.sanddorn.config.system.build.sdImage;
    #packages."x86_64-linux".sanddorn = self.nixosConfigurations.sanddorn.config.system.build.sdImage;

    nixosConfigurations = {
      /*birne = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/birne/configuration.nix

          ./modules/base.nix
          ./modules/autoupdate.nix
          ./modules/desktop.nix
          ./modules/printing.nix
          ./modules/wifi.nix
          ./modules/options.nix
          {
            fsr.enable_office_bloat = true;
          }

        ];
      };
      sanddorn = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          {
            nixpkgs.overlays = [ fsr-infoscreen.overlay."aarch64-linux"];
            nixpkgs.config.allowBroken = true;
            sdImage.compressImage = false;
          }
          ./hosts/sanddorn/configuration.nix
          ./modules/infoscreen.nix
          ./modules/base.nix
          ./modules/autoupdate.nix
          ./modules/wifi.nix
          ./modules/desktop.nix
          ./modules/options.nix
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          {
            fsr.enable_office_bloat = false;
          }
        ];
      };
      */
      durian = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.sops-nix.nixosModules.sops
          ./hosts/durian/configuration.nix
          ./modules/base.nix
          ./modules/sops.nix
          ./modules/keycloak.nix
  	  ./modules/nginx.nix
          {
            sops.defaultSopsFile = ./secrets/durian.yaml;
          }
        ];
      };
    };
  };
}
