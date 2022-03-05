{
  inputs = { 
    nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, sops-nix, ... }@inputs:  {
    nixosConfigurations.birne = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/birne/configuration.nix
      ];
    };
  };
}
