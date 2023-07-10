{ config, ... }:
{
  sops.secrets.mailman_ldap_search = {
    key = "portunus_search";
    owner = config.services.mailman.webUser;
  };
  services.mailman = {
    enable = true;
    serve.enable = true;
    webHosts = [ "lists.${config.fsr.domain}" ];
    hyperkitty.enable = true;
    enablePostfix = true;
    siteOwner = "mailman@${config.fsr.domain}";
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
  services.nginx.virtualHosts."lists.${config.fsr.domain}" = {
    enableACME = true;
    forceSSL = true;
    # deny non-uni access to prevent sending dozens of confirm emails
    locations."/mailman3".extraConfig = ''
      allow 141.30.0.0/16;
      allow 141.76.0.0/16;
      allow 172.16.0.0/16;
      deny all;
      uwsgi_pass unix:/run/mailman-web.socket;
    '';
  };
}
