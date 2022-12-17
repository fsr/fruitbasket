{ config, pkgs, lib, ... }:
let
  domain = "nc.${config.fsr.domain}";
in
{
  sops.secrets = {
    postgres_nextcloud = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    nextcloud_adminpass = {
      owner = "nextcloud";
      group = "nextcloud";
    };
  };

  services = {
    postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "nextcloud";
          ensurePermissions = {
            "DATABASE nextcloud" = "ALL PRIVILEGES";
          };
        }
      ];
      ensureDatabases = [ "nextcloud" ];
    };

    nextcloud = {
      enable = true;
      package = pkgs.nextcloud25; # Use current latest nextcloud package
      hostName = "${domain}";
      https = true; # Use https for all urls
      phpExtraExtensions = all: [
        all.ldap # Enable ldap php extension
      ];
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        dbpassFile = config.sops.secrets.postgres_nextcloud.path;
        adminpassFile = config.sops.secrets.nextcloud_adminpass.path;
        adminuser = "root";
      };
    };

    # Enable ACME and force SSL
    nginx = {
      recommendedProxySettings = true;
      virtualHosts = {
        "${domain}" = {
          enableACME = true;
          forceSSL = true;
        };
      };
    };
  };

  # ensure that postgres is running *before* running the setup
  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
}
