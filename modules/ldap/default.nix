{ config, pkgs, nixpkgs-unstable, system, ... }:
let
  domain = "auth.${config.networking.domain}";
  seedSettings = {
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
  # Use portunus from unstable branch until 24.05 is here
  disabledModules = [ "services/misc/portunus.nix" ];
  imports = [ "${nixpkgs-unstable}/nixos/modules/services/misc/portunus.nix" ];
  nixpkgs.overlays = [
    (_self: _super: {
      inherit (nixpkgs-unstable.legacyPackages.${system}) portunus;
    })
  ];

  sops.secrets = {
    "portunus/admin-password".owner = config.services.portunus.user;
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

      # normally disables port 389 (but not with our patch), use 636 with tls
      # `portunus.domain` resolves to localhost
      tls = true;
    };
  };

  security.pam.services.sshd.makeHomeDir = true;

  services.nginx = {
    enable = true;
    virtualHosts."${config.services.portunus.domain}" = {
      locations = {
        "/".proxyPass = "http://localhost:${toString config.services.portunus.port}";
      };
    };
  };
  networking.firewall = {
    extraInputRules = ''
      ip saddr { 141.30.86.192/26, 141.76.100.128/25, 141.30.30.169, 10.88.0.1/16 } tcp dport 636 accept comment "Allow ldaps access from office nets and podman"
    '';
  };
}
