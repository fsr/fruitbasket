{ config, ... }:
let
  domain = "manual.${config.networking.domain}";
in
{
  services.ese-manual = {
    enable = true;
    hostName = domain;
  };
  services.nginx = {
    virtualHosts."${domain}" = {
      addSSL = true;
      enableACME = true;
    };
  };
}
