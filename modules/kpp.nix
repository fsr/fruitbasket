{ config, ... }:
let
  domain = "kpp.ifsr.de";
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
