{ config, ... }:
let
  domain = "sso.${config.networking.domain}";
in
{
  sops.secrets."keykloak/db" = { };
  services.keycloak = {
    enable = true;
    settings = {
      http-port = 8086;
      https-port = 19000;
      hostname = domain;
      proxy = "edge";
    };
    # The module requires a password for the DB and works best with its own DB config
    # Does an automatic Postgresql configuration
    database = {
      passwordFile = config.sops.secrets."keycloak/db".path;
    };
    initialAdminPassword = "plschangeme";
  };
  services.nginx.virtualHosts."${domain}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.keycloak.settings.http-port}";
    };
  };
}
