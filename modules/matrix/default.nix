{ config, pkgs, ... }:
let
  domainServer = "matrix.${config.networking.domain}";
  domainClient = "chat.${config.networking.domain}";

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

  matrix-synapse-ldap3 = config.services.matrix-synapse.package.plugins.matrix-synapse-ldap3;
in
{
  imports = [ ./mautrix-telegram.nix ];
  sops.secrets.matrix_ldap_search = {
    key = "ldap/search-password";
    owner = config.systemd.services.matrix-synapse.serviceConfig.User;
  };
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

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
          root = pkgs.element-web.override {
            conf = {
              default_server_config = {
                inherit (clientConfig) "m.homeserver";
                "m.identity_server".base_url = "";
              };
              disable_3pid_login = true;
            };
          };
        };
      };
    };

    matrix-synapse = {
      enable = true;

      plugins = [ matrix-synapse-ldap3 ];


      log = {
        root.level = "WARNING";
      };
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
          text = ''
            modules:
              - module: ldap_auth_provider.LdapAuthProviderModule
                config:
                  enabled: true
                  uri: ldap://idm.ifsr.de:3389
                  base: ou=users,dc=ifsr,dc=de
                  attributes:
                    uid: cn
                    mail: mail
                    name: name
                  bind_dn: cn=ldap-search,ou=users,dc=ifsr,dc=de
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
