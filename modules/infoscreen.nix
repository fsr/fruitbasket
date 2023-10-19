{ pkgs, config, lib, ... }:
let
  domain = "infoscreen.${config.networking.domain}";
in
{
  services.nginx = {
    enable = true;
    virtualHosts."${domain}" = {
      addSSL = true;
      enableACME = true;
      root = "/srv/web/infoscreen/dist";
    };
  };
}
