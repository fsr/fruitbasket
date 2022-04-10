{
  inputs = { 
    nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    
    fsr-infoscreen.url = github:fsr/infoscreen;
  };
  outputs = { self, nixpkgs, sops-nix, fsr-infoscreen, ... }@inputs:  
  let 
  in {
    nixosConfigurations = {
      birne = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/birne/configuration.nix

          ./modules/base.nix
          ./modules/autoupdate.nix
          ./modules/desktop.nix
          ./modules/printing.nix
          ./modules/wifi.nix

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
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ];
      };
    };
  };
}
