{ config, lib, ... }:
let
  domain = "idm.${config.networking.domain}";
in
{
  sops.secrets."authentik/env" = { };
  services.authentik = {
    enable = true;
    nginx = {
      enable = true;
      host = domain;
      enableACME = true;
    };
    environmentFile = config.sops.secrets."authentik/env".path;
  };
}
