{ config, pkgs, lib, ... }:
let
  domain = "fsrewsp.${config.fsr.domain}";
in
{
  services = {
    postgresql = { 
        enable = true;
    };

    wordpress.sites."${domain}" = {
        virtualHost.enableACME = true;
    };
  };
}
