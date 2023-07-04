{ config, ... }:
let
  domain = "vault.${config.fsr.domain}";
in
{
  sops.secrets."vaultwarden_env".owner = "vaultwarden";
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    environmentFile = config.sops.secrets."vaultwarden_env".path;
    config = {
      domain = "https://${domain}";
      signupsAllowed = false;
      # somehow this works
      databaseUrl = "postgresql://vaultwarden@%2Frun%2Fpostgresql/vaultwarden";
      rocketPort = 8000;
    };
  };
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "vaultwarden";
        ensurePermissions = {
          "DATABASE vaultwarden" = "ALL PRIVILEGES";
        };
      }
    ];
    ensureDatabases = [ "vaultwarden" ];
  };
  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.rocketPort}";
    };
  };
}
