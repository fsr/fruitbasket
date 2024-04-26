{ config, ... }:
{
  sops.secrets.mailman_ldap_search = {
    key = "portunus/search-password";
    owner = config.services.mailman.webUser;
  };
  services.mailman = {
    enable = true;
    serve.enable = true;
    webHosts = [ "lists.${config.networking.domain}" ];
    hyperkitty.enable = true;
    enablePostfix = true;
    siteOwner = "mailman@${config.networking.domain}";
    settings = {
      database = {
        class = "mailman.database.postgresql.PostgreSQLDatabase";
        url = "postgresql://mailman@/mailman?host=/run/postgresql";
      };
    };
    webSettings = {
      DATABASES.default = {
        ENGINE = "django.db.backends.postgresql";
        NAME = "mailman-web";
      };
      ACCOUNT_EMAIL_UNKNOWN_ACCOUNTS = false;
      ACCOUNT_PREVENT_ENUMERATION = false;
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
  services.postfix = {
    relayDomains = [ "hash:/var/lib/mailman/data/postfix_domains" ];
    config = {
      mailbox_transport = "lmtp:unix:/run/dovecot2/dovecot-lmtp";
      transport_maps = [ "hash:/var/lib/mailman/data/postfix_lmtp" ];
      virtual_alias_maps = [ "hash:/var/lib/mailman/data/postfix_vmap" ];
      local_recipient_maps = [ "hash:/var/lib/mailman/data/postfix_lmtp" ];
    };
  };
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "mailman";
        ensureDBOwnership = true;
      }
      {
        name = "mailman-web";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "mailman" "mailman-web" ];
  };
  services.nginx.virtualHosts."lists.${config.networking.domain}" = {
    locations."/accounts/signup" = {
      extraConfig = ''
        allow 141.30.0.0/16;
        allow 141.76.0.0/16;
        deny all;
        uwsgi_pass unix:/run/mailman-web.socket;
      '';
    };
    locations."/robots.txt" = {
      extraConfig = ''
        add_header  Content-Type  text/plain;
        return 200 "User-agent: *\nDisallow: /\n";
      '';
    };
  };
}
