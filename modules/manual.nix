{ pkgs, config, lib, ... }:
let
  domain = "manual.${config.networking.domain}";
in
{
  services.nginx = {
    enable = true;
    virtualHosts."${domain}" = {
      addSSL = true;
      enableACME = true;
      root = "/srv/web/manual-website/site";
    };
  };
}
