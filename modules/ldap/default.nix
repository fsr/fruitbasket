{ config, lib, pkgs, nixpkgs-unstable, system, ... }:
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
    (self: super: {
      inherit (nixpkgs-unstable.legacyPackages.${system}) portunus;
    })
  ];

  sops.secrets = {
    "portunus/admin-password".owner = config.services.portunus.user;
    "portunus/search-password".owner = config.services.portunus.user;
    "dex/environment".owner = config.systemd.services.dex.serviceConfig.User;
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
    dex.enable = true;

    ldap = {
      suffix = "dc=ifsr,dc=de";
      searchUserName = "search";

      # normally disables port 389 (but not with our patch), use 636 with tls
      # `portunus.domain` resolves to localhost
      tls = true;
    };
  };

  services.dex.settings = {
    oauth2.skipApprovalScreen = true;
    frontend = {
      issuer = "iFSR Schliboleth";
      logoURL = "https://wiki.ifsr.de/images/3/3b/LogoiFSR.png";
      theme = "dark";
    };
  };

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
  };

  security.pam.services.sshd.makeHomeDir = true;

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
  networking.firewall = {
    extraInputRules = ''
      ip saddr { 141.30.86.192/26, 141.76.100.128/25 } tcp dport 636 accept comment "Allow ldaps access from office nets"
    '';
  };
}
