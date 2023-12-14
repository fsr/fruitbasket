{ config, lib, course-management, ... }:
let
  hostName = "kurse-phil.${config.networking.domain}";
in
{
  services.nginx.virtualHosts."${hostName}" = {
    locations."/".proxyPass = "http://127.0.0.1:8084";
    enableACME = true;
    forceSSL = true;
  };

  sops.secrets = {
    "course-management-phil/secret-key" = { };
    "course-management-phil/adminpass" = { };
  };
  containers."courses-phil" = {
    autoStart = true;
    extraFlags = [
      "--load-credential=course-secret-key:${config.sops.secrets."course-management-phil/secret-key".path}"
      "--load-credential=course-adminpass:${config.sops.secrets."course-management-phil/adminpass".path}"
    ];
    config = { pkgs, config, ... }: {
      system.stateVersion = "23.05";
      networking.domain = "ifsr.de";
      imports = [
        course-management.nixosModules.default
      ];
      systemd.services.course-management = {
        after = [ "postgresql.service" ];
        serviceConfig = {
          LoadCredential = [
            "secret-key:course-secret-key"
            "adminpass:course-adminpass"
          ];
        };
      };
      services.course-management = {
        inherit hostName;
        enable = true;
        listenPort = 5001;

        settings = {
          secretKeyFile = "$CREDENTIALS_DIRECTORY/secret-key";
          adminPassFile = "$CREDENTIALS_DIRECTORY/adminpass";
          admins = [{
            name = "Root iFSR";
            email = "root@${config.networking.domain}";
          }];
          database = {
            ENGINE = "django.db.backends.postgresql";
            NAME = "course-management";
          };
          email = lib.mkDefault {
            fromEmail = "noreply@${config.networking.domain}";
            serverEmail = "root@${config.networking.domain}";
          };
        };
      };
      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "root@${config.networking.domain}";
        };
      };
      services.postgresql = {
        enable = true;
        enableTCPIP = lib.mkForce false;
        ensureUsers = [{
          name = "course-management";
          ensureDBOwnership = true;
        }];
        ensureDatabases = [ "course-management" ];
      };
      systemd.services.postgresql.serviceConfig.ExecStart = lib.mkForce "${pkgs.postgresql}/bin/postgres -c listen_addresses=''";
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;


        virtualHosts.${hostName} = {
          listen = [{
            addr = "127.0.0.1";
            port = 8084;
          }];
        };
      };

    };
  };
}
