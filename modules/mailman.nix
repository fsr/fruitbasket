{ config, ... }:
{
  sops.secrets.mailman_ldap_search = {
    key = "portunus/search-password";
    owner = config.services.mailman.webUser;
  };
  services.mailman = {
    enable = true;
    serve.enable = true;
    webHosts = [ "lists.${config.fsr.domain}" ];
    hyperkitty.enable = true;
    enablePostfix = true;
    siteOwner = "mailman@${config.fsr.domain}";
    settings = {
      database = {
        class = "mailman.database.postgresql.PostgreSQLDatabase";
        url = "postgresql://mailman@/mailman?host=/run/postgresql";
      };
    };
    webSettings = {
      DATABASES.default = {
        ENGINE = "django.db.backends.postgresql";
        NAME = "mailmanweb";
      };
    };
    ldap = {
      enable = true;
      serverUri = "ldap://localhost";
      bindDn = "uid=search, ou=users, dc=ifsr, dc=de";
      bindPasswordFile = config.sops.secrets.mailman_ldap_search.path;
      userSearch = {
        ou = "ou=users, dc=ifsr, dc=de";
        query = "(&(objectClass=posixAccount)(uid=%(user)s))";
      };
      groupSearch = {
        ou = "ou=groups, dc=ifsr, dc=de";
        query = "(objectClass=groupOfNames)";
        type = "groupOfNames";
      };
      superUserGroup = "cn=admins,ou=groups,dc=ifsr,dc=de";
    };
  };
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "mailman";
        ensurePermissions = {
          "DATABASE mailman" = "ALL PRIVILEGES";
        };
      }
      {
        name = "mailman-web";
        ensurePermissions = {
          "DATABASE mailmanweb" = "ALL PRIVILEGES";
        };
      }
    ];
    ensureDatabases = [ "mailman" "mailmanweb" ];
  };
  services.nginx.virtualHosts."lists.${config.fsr.domain}" = {
    enableACME = true;
    forceSSL = true;
  };
}
