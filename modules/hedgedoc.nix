{ config, pkgs, lib, ... }:
let
  domain = "pad.${config.fsr.domain}";
in
{
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
      settings = {
        port = 3002;
        domain = "${domain}";
        protocolUseSSL = true;
        dbURL = "postgres://hedgedoc:\${DB_PASSWORD}@localhost:5432/hedgedoc";
        sessionSecret = "\${SESSION_SECRET}";
        csp = {
          enable = true;
          directives = {
            scriptSrc = "${domain}";
          };
          upgradeInsecureRequest = "auto";
          addDefaults = true;
        };
        allowGravatar = false;

        ## authentication
        # disable email
        email = false;
        allowEmailRegister = false;
        # allow anonymous editing, but not creation of pads
        allowAnonymous = false;
        allowAnonymousEdits = true;
        defaultPermission = "limited";
        # ldap auth
        ldap =
          let portunus = config.services.portunus;
          in rec {
            url = "ldaps://${portunus.domain}";
            searchBase = "ou=users,${portunus.ldap.suffix}";
            searchFilter = "(uid={{username}})";
            bindDn = "uid=${portunus.ldap.searchUserName},${searchBase}";
            bindCredentials = "\${LDAP_CREDENTIALS}";
            useridField = "uid";
            providerName = "iFSR";
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
            proxyPass = "http://[::1]:${toString config.services.hedgedoc.settings.port}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };

  sops.secrets =
    let
      user = config.systemd.services.hedgedoc.serviceConfig.User;
    in
    {
      postgres_hedgedoc.owner = user;
      hedgedoc_session_secret.owner = user;
      hedgedoc_ldap_search = {
        key = "portunus/users/search-password";
        owner = user;
      };
    };

  systemd.services.hedgedoc.preStart = lib.mkBefore ''
    export DB_PASSWORD="$(cat ${config.sops.secrets.postgres_hedgedoc.path})"
    export SESSION_SECRET="$(cat ${config.sops.secrets.hedgedoc_session_secret.path})"
    export LDAP_CREDENTIALS="$(cat ${config.sops.secrets.hedgedoc_ldap_search.path})"
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
