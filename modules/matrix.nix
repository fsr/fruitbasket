{ config, pkgs, lib, ... }:
let
  domainServer = "matrix.${config.fsr.domain}";
  domainClient = "chat.${config.fsr.domain}";

  clientConfig = {
    "m.homeserver" = {
      base_url = "https://${domainServer}:443";
      server_name = domainServer;
    };
    "m.identity_server" = { };
  };
  serverConfig = {
    "m.server" = "${domainServer}:443";
  };

  mkWellKnown = data: ''
    add_header Content-Type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in
{
  # sops.secrets = {
  #   synapse_registration_secret = {
  #     owner = "matrix-synapse";
  #     group = "matrix-synapse";
  #   };
  # };

  services = {
    postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "matrix-synapse";
        }
      ];
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
            };
          };
        };
      };
    };

    matrix-synapse = {
      enable = true;

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

        # TODO: ldap
        registration_shared_secret = "registration_shared_secret";
      };
      # extraConfigFiles = [
      #   (pkgs.writeTextFile {
      #     name = "matrix-synapse-extra-config.yml";
      #     text = ''
      #     '';
      #   })
      # ];
    };
  };

  systemd.services.matrix-synapse.after = [ "matrix-synapse-pgsetup.service" ];

  systemd.services.matrix-synapse-pgsetup = {
    description = "Prepare Synapse postgres database";
    wantedBy = [ "multi-user.target" ];
    after = [ "networking.target" "postgresql.service" ];
    serviceConfig.Type = "oneshot";

    path = [ pkgs.sudo config.services.postgresql.package ];

    # create database for synapse. will silently fail if already exists
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
