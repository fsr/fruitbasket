{ config, lib, pkgs, ... }:
let
  domain = "auth.${config.fsr.domain}";

  portunusUser = "portunus";
  portunusGroup = "portunus";

  ldapUser = "openldap";
  ldapGroup = "openldap";
in
{
  sops.secrets = {
    "portunus/users/admin-password" = {
      owner = "${portunusUser}";
      group = "${portunusGroup}";
    };
    "portunus/users/search-password" = {
      owner = "${portunusUser}";
      group = "${portunusGroup}";
    };
    "dex/environment" = {
      owner = config.systemd.services.dex.serviceConfig.User;
      group = "dex";
    };
  };

  services.dex.settings.oauth2.skipApprovalScreen = true;

  services.portunus = {
    enable = true;
    user = "${portunusUser}";
    group = "${portunusGroup}";
    domain = "${domain}";
    port = 8081;
    userRegex = "[a-z_][a-z0-9_.-]*\$?";
    dex = {
      enable = true;
    };
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
  systemd.services.dex.serviceConfig = {
    DynamicUser = lib.mkForce false;
    EnvironmentFile = config.sops.secrets."dex/environment".path;
    StateDirectory = "dex";
    User = "dex";
  };

  users = {
    groups = {
      dex = {};

      "${portunusGroup}" = {
        name = "${portunusGroup}";
        members = [ "${portunusUser}" ];
      };
      "${ldapGroup}" = {
        name = "${ldapGroup}";
        members = [ "${ldapUser}" ];
      };
    };
    users = {
      dex = {
        group = "dex";
        isSystemUser = true;
      };
      "${portunusUser}" = {
        isSystemUser = true;
        group = "${portunusGroup}";
      };

      "${ldapUser}" = {
        isSystemUser = true;
        group = "${ldapGroup}";
      };
    };
    ldap =
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
        passwordFile = config.sops.secrets."portunus/users/search-password".path;
      };
      daemon.enable = true;
    };
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
  nixpkgs.overlays = [
    (self: super:
{
  portunus = super.portunus.overrideAttrs (old: {
    src = super.fetchFromGitHub {
      owner = "revol-xut";
      repo = "portunus";
      rev = "8bad0661ecca9276991447f8e585c20c450ad57a";
      sha256 = "sha256-59AvNWhnsvtrVmAJRcHeNOYOlHCx1ZZSqwFvyAM+Ye8=";
    };
  });
})
];

}
