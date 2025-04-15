{ config, ... }:
let
  domain = "idm.${config.networking.domain}";
in
{
  age.secrets.authentik-core = {
    file = ../../../../secrets/nuc/authentik/core.age;
  };
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
