{ config, pkgs, ... }:
let
  domain = "auth.${config.fsr.domain}";

  portunusUser = "portunus";
  portunusGroup = "portunus";

  ldapUser = "openldap";
  ldapGroup = "openldap";
in
{
  sops.secrets.unix_ldap_search = {
    key = "portunus_search";
    owner = config.systemd.services.nslcd.serviceConfig.User;
  };


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
    package = pkgs.portunus.overrideAttrs (old: {
      patches = [ ./0001-update-user-validation-regex.patch ];
    });
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
      #tls = true;
    };

    seedPath = ../../config/portunus_seeds.json;
  };

  #users.ldap = {
  #enable = true;
  #server = "ldap://localhost";
  #base = "${config.services.portunus.ldap.suffix}";
  #};
  users.ldap =
    let
      portunus = config.services.portunus;
      base = "ou=users,${portunus.ldap.suffix}";
    in
    {
      enable = true;
      server = "ldap://localhost";
      base = base;
      bind = {
        distinguishedName = "uid=${portunus.ldap.searchUserName},${base}";
        passwordFile = config.sops.secrets.unix_ldap_search.path;
      };
      daemon.enable = true;
    };

  security.pam.services.sshd.text = ''
    # Account management.
    account sufficient ${pkgs.nss_pam_ldapd}/lib/security/pam_ldap.so
    account required pam_unix.so

    # Authentication management.
    auth sufficient pam_unix.so  likeauth try_first_pass
    auth sufficient ${pkgs.nss_pam_ldapd}/lib/security/pam_ldap.so use_first_pass
    auth required pam_deny.so

    # Password management.
    password sufficient pam_unix.so nullok sha512
    password sufficient ${pkgs.nss_pam_ldapd}/lib/security/pam_ldap.so

    # Session management.
    session required pam_env.so conffile=/etc/pam/environment readenv=0
    session required pam_unix.so
    session required pam_loginuid.so
    session optional pam_mkhomedir.so
    session optional ${pkgs.nss_pam_ldapd}/lib/security/pam_ldap.so
    session optional ${pkgs.systemd}/lib/security/pam_systemd.so

  '';

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
