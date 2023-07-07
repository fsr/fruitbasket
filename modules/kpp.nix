{ config, ... }:
let
  domain = "kpp.${config.fsr.domain}";
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
