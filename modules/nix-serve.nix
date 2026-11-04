{ config, ... }:
let
  domain = "cache.${config.networking.domain}";
in
{
  sops.secrets."nix-serve/key" = { };
  containers.nix-serve = {
    extraFlags = [
      "--load-credential=nix-key:${config.sops.secrets."nix-serve/key".path}"
    ];
    config = { pkgs, ... }: {
      services.nix-serve = {
        enable = true;
        package = pkgs.nix-serve-ng;
        # gets fetched as a systemd credential automatically
        secretKeyFile = "nix-key";
        port = 5002;
      };

    };

  };
  services.nginx.virtualHosts."${domain}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.containers.nix-serve.config.services.nix-serve.port}";
    };
  };
}
