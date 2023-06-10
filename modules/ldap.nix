{ config, lib, pkgs, ... }:
let
  domain = "auth.${config.fsr.domain}";
in
{
  sops.secrets = {
    "portunus/users/admin-password".owner = config.services.portunus.user;
    "portunus/users/search-password".owner = config.services.portunus.user;
    "dex/environment".owner = config.systemd.services.dex.serviceConfig.User;
    nslcd_ldap_search = {
      key = "portunus/users/search-password";
      owner = config.systemd.services.nslcd.serviceConfig.User;
    };
  };

  services = {
    portunus = {
      enable = true;
      domain = "${domain}";
      port = 8681;
      userRegex = "[a-z_][a-z0-9_.-]*\$?";
      dex = {
        enable = true;
      };
      ldap = {
        suffix = "dc=ifsr,dc=de";
        searchUserName = "search";

        # disables port 389, use 636 with tls
        # `portunus.domain` resolves to localhost
        tls = false;
      };

      seedPath = ../config/portunus_seeds.json;
    };

    dex.settings.oauth2.skipApprovalScreen = true;

    nginx = {
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
  };

  systemd.services.dex.serviceConfig = {
    DynamicUser = lib.mkForce false;
    EnvironmentFile = config.sops.secrets."dex/environment".path;
    StateDirectory = "dex";
    User = "dex";
  };

  users = {
    groups.dex = { };

    users.dex = {
      group = "dex";
      isSystemUser = true;
    };

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

  nixpkgs.overlays = [
    (self: super:
      {
        portunus = super.portunus.overrideAttrs (old: {
          src = super.fetchFromGitHub {
            owner = "revol-xut";
            repo = "portunus";
            rev = "c95528e21782b3477203bc29fc85515f2cb8c8cb";
            sha256 = "sha256-CmH0HKr+pNDnw0qfDucQrCixFg7Yh8r7Rt7v9+6pNXc=";
          };
        });
      })
  ];
}
