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
      };
    };
  };
  services.nginx.virtualHosts."lists.${config.fsr.domain}" = {
    enableACME = true;
    forceSSL = true;
  };
}
