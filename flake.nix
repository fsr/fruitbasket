{
  inputs = { 
    nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, sops-nix, ... }@inputs: 
  let
    overlays = [
    ];
  in {
    nixosConfigurations.brine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/birne/configuration.nix
        ( _: { nixpkgs.overlays = overlays; } )
      ];
    };
  };
}
