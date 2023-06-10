{ config, pkgs, lib, ... }:
let
  domainServer = "matrix.${config.fsr.domain}";
  domainClient = "chat.${config.fsr.domain}";

  clientConfig = {
    "m.homeserver" = {
      base_url = "https://${domainServer}:443";
      server_name = domainServer;
    };
  };
  serverConfig = {
    "m.server" = "${domainServer}:443";
  };

  mkWellKnown = data: ''
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';

  # build ldap3 plugin from git because it's very outdated in nixpkgs
  matrix-synapse-ldap3 = pkgs.python3.pkgs.callPackage ../pkgs/matrix-synapse-ldap3.nix { };
  # matrix-synapse-ldap3 = config.services.matrix-synapse.package.plugins.matrix-synapse-ldap3;
in
{
  sops.secrets.matrix_ldap_search = {
    key = "portunus/users/search-password";
    owner = config.systemd.services.matrix-synapse.serviceConfig.User;
  };

  services = {
    postgresql = {
      enable = true;
      ensureUsers = [{
        name = "matrix-synapse";
      }];
    };

    nginx = {
      recommendedProxySettings = true;
      virtualHosts = {
        # synapse
        "${domainServer}" = {
          enableACME = true;
          forceSSL = true;

          # homeserver discovery
          locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
          locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;

          # 404 on /
          locations."/".extraConfig = "return 404;";

          # proxy to synapse
          locations."/_matrix".proxyPass = "http://[::1]:8008";
          locations."/_synapse/client".proxyPass = "http://[::1]:8008";
        };

        # element
        "${domainClient}" = {
          enableACME = true;
          forceSSL = true;

          root = pkgs.element-web.override {
            conf = {
              default_server_config = clientConfig;
              disable_3pid_login = true;
            };
          };
        };
      };
    };

    matrix-synapse = {
      enable = true;

      plugins = [ matrix-synapse-ldap3 ];

      settings = {
        server_name = domainServer;

        listeners = [{
          port = 8008;
          bind_addresses = [ "::1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [{
            names = [ "client" "federation" ];
            compress = false;
          }];
        }];
      };

      extraConfigFiles = [
        (pkgs.writeTextFile {
          name = "matrix-synapse-extra-config.yml";
          text = let portunus = config.services.portunus; in ''
            modules:
              - module: ldap_auth_provider.LdapAuthProviderModule
                config:
                  enabled: true
                  uri: ldap://localhost
                  base: ou=users,${portunus.ldap.suffix}
                  # taken from kaki config
                  attributes:
                    uid: uid
                    mail: uid
                    name: cn
                  bind_dn: uid=search,ou=users,${portunus.ldap.suffix}
                  bind_password_file: ${config.sops.secrets.matrix_ldap_search.path}
          '';
        })
      ];
    };
  };

  systemd.services.matrix-synapse.after = [ "matrix-synapse-pgsetup.service" ];

  systemd.services.matrix-synapse-pgsetup = {
    description = "Prepare Synapse postgres database";
    wantedBy = [ "multi-user.target" ];
    after = [ "networking.target" "postgresql.service" ];
    serviceConfig.Type = "oneshot";

    path = [ pkgs.sudo config.services.postgresql.package ];

    # create database for synapse. will silently fail if it already exists
    script = ''
      sudo -u ${config.services.postgresql.superUser} psql <<SQL
        CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
          ENCODING 'UTF8'
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";
      SQL
    '';
  };
}
