{pkgs, config, lib, ...}: {
  
  sops.secrets.postgres_keycloak.owner = config.systemd.services.keycloak.serviceConfig.User;

  services = {
    keycloak = {
      enable = true;

      settings = {
        hostname = "keycloak.durian.tassilo-tanneberger.de";
      };

      database = {
        username = "keycloak";
        type = "postgresql";
        passwordFile = config.sops.secrets.postgres_keycloak.path;
        name = "keycloak";
        host = "localhost";
      };
    };
    postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "keycloak";
          ensurePermissions = {
            "DATABASE keycloak" = "ALL PRIVILEGES";
          };
        }
      ];
      ensureDatabases = [ "keycloak" ];
    };
  };
}
