{ config, pkgs, lib, ... }:
{
  sops.secrets.postgres_mediawiki.owner = config.systemd.services.mediawiki.serviceConfig.User;
  sops.secrets.mediawiki_initial_admin.owner = config.systemd.services.mediawiki.serviceConfig.User;
  services = {
    mediawiki = {
      enable = true;
      name = "FSR Wiki";
      passwordFile = config.sops.secrets.mediawiki_initial_admin.path;
      database = {
        user = "mediawiki";
        type = "postgres";
        socket = "/var/run/postgresql";
        port = 5432;
        name = "mediawiki";
        host = "localhost";
        passwordFile = config.sops.secrets.postgres_mediawiki.path;
        createLocally = false;
      };
      virtualHost = {
        hostName = "wiki.quitte.tassilo-tanneberger.de";
        adminAddr = "root@ifsr.de";
        forceSSL = true;
        enableACME = true;
      };
    };
    postgresql = {
      enable = true;
    };
  };
  systemd.services.mediawiki-pgsetup = {
    description = "Prepare Mediawiki postgres database";
    wantedBy = [ "multi-user.target" ];
    after = [ "networking.target" "postgresql.service" ];
    serviceConfig.Type = "oneshot";

    path = [ pkgs.sudo config.services.postgresql.package ];
    script = ''
      sudo -u ${config.services.postgresql.superUser} psql -c "ALTER ROLE mediawiki WITH PASSWORD '$(cat ${config.sops.secrets.postgres_mediawiki.path})'"
    '';
  };
}
