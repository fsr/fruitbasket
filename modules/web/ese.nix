{ config, ... }:
let
  domain = "ese.${config.networking.domain}";
in
{
  services.nginx = {
    virtualHosts."${domain}" = {
      locations."= /" = {
        return = "301 /2024/";
      };
      locations."/" = {
        root = "/srv/web/ese/served";
        tryFiles = "$uri $uri/ =404";
      };
    };
  };
}
