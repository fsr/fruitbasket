{ config, specialArgs, ... }: let
  domain = "notenrechner.${config.networking.domain}";
in {
  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;
    enableACME = true;
    root = specialArgs.notenrechner.packages."x86_64-linux".default;
  };
}
