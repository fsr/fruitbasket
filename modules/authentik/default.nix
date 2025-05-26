{ config, ... }:
let
  domain = "idm.${config.networking.domain}";
in
{
  sops.secrets."authentik/core" = { };
  sops.secrets."authentik/ldap" = { };
  services.authentik = {
    enable = true;
    nginx = {
      enable = true;
      host = domain;
      enableACME = true;
    };
    environmentFile = config.sops.secrets."authentik/core".path;
  };
  services.authentik-ldap = {
    enable = true;
    environmentFile = config.sops.secrets."authentik/ldap".path;
  };
}
