{ config, lib, pkgs, ... }:
let
  domain = "auth.${config.fsr.domain}";
  seed = {
    groups = [
      {
        name = "admins";
        long_name = "Portunus Admin";
        members = [ "admin" ];
        permissions.portunus.is_admin = true;
      }
      {
        name = "search";
        long_name = "LDAP search group";
        members = [ "search" ];
        permissions.ldap.can_read = true;
      }
      {
        name = "fsr";
        long_name = "Mitglieder des iFSR";
      }
    ];
    users = [
      {
        login_name = "admin";
        given_name = "admin";
        family_name = "admin";
        password.from_command = [
          "${pkgs.coreutils}/bin/cat"
          config.sops.secrets."portunus/admin-password".path
        ];
      }
      {
        login_name = "search";
        given_name = "search";
        family_name = "search";
        password.from_command = [
          "${pkgs.coreutils}/bin/cat"
          config.sops.secrets."portunus/search-password".path
        ];
      }
    ];
  };
in
{
  sops.secrets = {
    "portunus/admin-password".owner = config.services.portunus.user;
    "portunus/search-password".owner = config.services.portunus.user;
    "dex/environment".owner = config.systemd.services.dex.serviceConfig.User;
    nslcd_ldap_search = {
      key = "portunus/search-password";
      owner = config.systemd.services.nslcd.serviceConfig.User;
    };
  };

  services.portunus = {
    enable = true;
    package = pkgs.portunus.overrideAttrs (old: {
      patches = [
        ./0001-update-user-validation-regex.patch
        ./0002-both-ldap-and-ldaps.patch
      ];
    });

    inherit domain;
    port = 8681;
    dex.enable = true;
    seedPath = pkgs.writeText "portunus-seed.json" (builtins.toJSON seed);

    ldap = {
      suffix = "dc=ifsr,dc=de";
      searchUserName = "search";

      # normally disables port 389 (but not with our patch), use 636 with tls
      # `portunus.domain` resolves to localhost
      tls = true;
    };
  };

  services.dex.settings.oauth2.skipApprovalScreen = true;

  systemd.services.dex.serviceConfig = {
    DynamicUser = lib.mkForce false;
    EnvironmentFile = config.sops.secrets."dex/environment".path;
    StateDirectory = "dex";
    User = "dex";
  };

  users = {
    users.dex = {
      group = "dex";
      isSystemUser = true;
    };
    groups.dex = { };

    ldap =
      let portunus = config.services.portunus;
      in rec {
        enable = true;
        server = "ldap://localhost";
        base = "ou=users,${portunus.ldap.suffix}";
        bind = {
          distinguishedName = "uid=${portunus.ldap.searchUserName},${base}";
          passwordFile = config.sops.secrets.nslcd_ldap_search.path;
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
        "/dex".proxyPass = "http://localhost:${toString config.services.portunus.dex.port}";
      };
    };
  };
}
