{ config, ... }:
let
  domain = "vault.${config.networking.domain}";
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
      databaseUrl = "postgresql://vaultwarden@%2Frun%2Fpostgresql/vaultwarden";
      rocketPort = 8000;
      smtpHost = "127.0.0.1";
      smtpPort = 25;
      smtpSSL = false;
      smtpFrom = "noreply@${config.networking.domain}";
      smtpFromName = "iFSR Vaultwarden";
    };
  };
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
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
