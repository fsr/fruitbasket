{ config, ... }:
let
  domain = "infoscreen.${config.networking.domain}";
in
{
  services.nginx = {
    enable = true;
    virtualHosts."${domain}" = {
      root = "/srv/web/infoscreen/dist";
    };
  };
}
