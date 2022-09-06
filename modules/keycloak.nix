{ pkgs, config, lib, ... }: {

  sops.secrets.postgres_keycloak = {
    owner = config.systemd.services.keycloak.serviceConfig.User;
    group = "keycloak";
  };

  users.users.keycloak = {
    name = "keycloak";
    isSystemUser = true;
    group = "keycloak";
  };

  users.groups.keycloak = {
    name = "keycloak";
    members = [ "keycloak" ];
  };

  services = {
    keycloak = {
      enable = true;

      settings = {
        hostname = "keycloak.quitte.tassilo-tanneberger.de";
        http-host = "127.0.0.1";
        http-port = 8000;
        https-port = 8001;
        proxy = "edge";
      };

      database = {
        username = "keycloak";
        type = "postgresql";
        passwordFile = config.sops.secrets.postgres_keycloak.path;
        name = "keycloak";
        host = "localhost";
        createLocally = true;
      };
    };
    postgresql = {
      enable = true;
    };
    nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "${config.services.keycloak.settings.hostname}" = {
          enableACME = true;
          forceSSL = true;
          http2 = true;
          locations = {
            "/" =
              let
                cfg = config.services.keycloak.settings;
              in
              {
                proxyPass = "http://${cfg.http-host}:${toString cfg.http-port}";
              };
          };
        };
      };
    };
  };
}
