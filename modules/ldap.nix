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

  sops.secrets."portunus_admin" = {
    owner = "${portunusUser}";
    group = "${portunusGroup}";
  };

  services.portunus = {
    enable = true;
    user = "${portunusUser}";
    group = "${portunusGroup}";
    domain = "${domain}";
    ldap = {
      user = "${ldapUser}";
      group = "${ldapGroup}";
      suffix = "dc=ifsr,dc=de";
      tls = true;
    };

    seedPath = ../config/portunus_seeds.json;
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

  networking.firewall.allowedTCPPorts = [
    80 # http
    443 # https
  ];
}
