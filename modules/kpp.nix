{ config, ... }:
let
  domain = "kpp.${config.networking.domain}";
in
{
  services.kpp = {
    enable = true;
    hostName = domain;
  };
  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
  };

}
