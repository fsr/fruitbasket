{ config, ... }:
let
  # temporary url, zum testen auf laptop zuhause
  tld = "moe";
  hostname = "eisvogel";
  domain = "portunus.${hostname}.${tld}";

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

  # TODO: eigenes secrets.yaml für seedfile?
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
      suffix = "dc=${hostname},dc=${tld}";
      tls = true;
    };

    seedPath = "../config/portunus_seeds.json";
  };

  users.ldap = {
    enable = true;
    server = "ldaps://${domain}";
    base = "dc=${hostname},dc=${tld}";
    # useTLS = true; # nicht nötig weil ldaps domain festgelegt. würde sonst starttls auf port 389 versuchen
  };

  services.nginx = {
    enable = true;
    virtualHosts."${config.services.portunus.domain}" = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/".proxyPass = "http://localhost:${toString config.services.portunus.port}";
        "/dex".proxyPass = "http://localhost:${toString config.services.portunus.dex.port}";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80 # http
    443 # https
    636 # ldaps
  ];
}
