{ config, pkgs, lib, ... }:
let
  domain = "pad.ifsr.de";
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
        db = {
          dialect = "postgres";
          host = "/run/postgresql/";
        };
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
        ldap = rec {
          url = "ldap://localhost";
          searchBase = "ou=users,${config.services.portunus.ldap.suffix}";
          searchFilter = "(uid={{username}})";
          bindDn = "uid=${config.services.portunus.ldap.searchUserName},${searchBase}";
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
      hedgedoc_session_secret.owner = user;
      hedgedoc_ldap_search = {
        key = "portunus/search-password";
        owner = user;
      };
    };

  systemd.services.hedgedoc.preStart = lib.mkBefore ''
    export SESSION_SECRET="$(cat ${config.sops.secrets.hedgedoc_session_secret.path})"
    export LDAP_CREDENTIALS="$(cat ${config.sops.secrets.hedgedoc_ldap_search.path})"
  '';
}
