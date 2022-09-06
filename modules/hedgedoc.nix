{ config, pkgs, lib, ... }:
let 
  domain = "pad.quitte.tassilo-tanneberger.de";
in {
  services = {
    postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "hedgedoc";
          ensurePermissions = {
            "DATABASE hedgedoc" = "ALL PRIVILEGES";
          };
        }
      ];
      ensureDatabases = [ "hedgedoc" ];
    };

    hedgedoc = {
      enable = true;
      configuration = {
        port = 3002;
        domain = "${domain}";
        protocolUseSSL = true;
        dbURL = "postgres://hedgedoc:\${DB_PASSWORD}@localhost:5432/hedgedoc";
        sessionSecret = "\${SESSION_SECRET}";
        allowAnonymousEdits = true;
        csp = {
          enable = true;
          directives = {
            scriptSrc = "${domain}";
          };
          upgradeInsecureRequest = "auto";
          addDefaults = true;
        };
      };
    };

    nginx = {
      recommendedProxySettings = true;
      virtualHosts = {
        "${domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3002";
            proxyWebsockets = true;
          };
        };
      };
    };
  };

  sops.secrets.postgres_hedgedoc.owner = config.systemd.services.hedgedoc.serviceConfig.User;
  sops.secrets.hedgedoc_session_secret.owner = config.systemd.services.hedgedoc.serviceConfig.User;

  systemd.services.hedgedoc.preStart = lib.mkBefore ''
    export DB_PASSWORD="$(cat ${config.sops.secrets.postgres_hedgedoc.path})"
    export SESSION_SECRET="$(cat ${config.sops.secrets.hedgedoc_session_secret.path})"
  '';
  systemd.services.hedgedoc.after = [ "hedgedoc-pgsetup.service" ];

  systemd.services.hedgedoc-pgsetup = {
    description = "Prepare HedgeDoc postgres database";
    wantedBy = [ "multi-user.target" ];
    after = [ "networking.target" "postgresql.service" ];
    serviceConfig.Type = "oneshot";

    path = [ pkgs.sudo config.services.postgresql.package ];
    script = ''
      sudo -u ${config.services.postgresql.superUser} psql -c "ALTER ROLE hedgedoc WITH PASSWORD '$(cat ${config.sops.secrets.postgres_hedgedoc.path})'"
    '';
  };
}
