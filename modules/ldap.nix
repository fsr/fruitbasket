{ config, ... }:
let
  domain = "auth.${config.fsr.domain}";

  portunusUser = "portunus";
  portunusGroup = "portunus";

  ldapUser = "openldap";
  ldapGroup = "openldap";
in
{
  users.users."${portunusUser}" = {
    isSystemUser = true;
    group = "${portunusGroup}";
  };

  users.groups."${portunusGroup}" = {
    name = "${portunusGroup}";
    members = [ "${portunusUser}" ];
  };

  users.users."${ldapUser}" = {
    isSystemUser = true;
    group = "${ldapGroup}";
  };

  users.groups."${ldapGroup}" = {
    name = "${ldapGroup}";
    members = [ "${ldapUser}" ];
  };

  sops.secrets = {
    "portunus_admin" = {
      owner = "${portunusUser}";
      group = "${portunusGroup}";
    };
    "portunus_search" = {
      owner = "${portunusUser}";
      group = "${portunusGroup}";
    };
  };

  services.portunus = {
    enable = true;
    user = "${portunusUser}";
    group = "${portunusGroup}";
    domain = "${domain}";
    port = 8081;

    ldap = {
      user = "${ldapUser}";
      group = "${ldapGroup}";

      suffix = "dc=ifsr,dc=de";
      searchUserName = "search";

      # disables port 389, use 636 with tls
      # `portunus.domain` resolves to localhost
      tls = true;
    };

    seedPath = ../config/portunus_seeds.json;
  };

  users.ldap = {
    enable = true;
    server = "ldap://localhost";
    base = "${config.services.portunus.ldap.suffix}";
  };

  services.nginx = {
    enable = true;
    virtualHosts."${config.services.portunus.domain}" = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/".proxyPass = "http://localhost:${toString config.services.portunus.port}";
      };
    };
  };
}
