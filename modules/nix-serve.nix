{ config, pkgs, ... }:
let
  domain = "cache.${config.networking.domain}";
in
{
  sops.secrets."nix-serve/key" = { };
  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.sops.secrets."nix-serve/key".path;
    port = 5002;
  };
  services.nginx.virtualHosts."${domain}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.nix-serve.port}";
    };
  };
}
