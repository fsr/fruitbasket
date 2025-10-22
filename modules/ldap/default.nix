{ config, pkgs, ... }:
let
  domain = "auth.${config.networking.domain}";
  seedSettings = {
    groups = [
      {
        name = "admins";
        long_name = "Portunus Admin";
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
    "portunus/search-password".owner = config.services.portunus.user;
  };

  services.portunus = {
    enable = true;
    package = pkgs.portunus.overrideAttrs (_old: {
      patches = [
        ./0001-update-user-validation-regex.patch
        ./0002-both-ldap-and-ldaps.patch
        ./0003-gecos-ascii-escape.patch
        ./0004-make-givenName-optional.patch
      ];
      doCheck = false; # posix regex related tests break
    });

    inherit domain seedSettings;
    port = 8681;
    ldap = {
      suffix = "dc=ifsr,dc=de";
      searchUserName = "search";
    };
  };

  security.pam.services.sshd.makeHomeDir = true;
}
