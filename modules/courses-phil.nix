{ config, lib, sops-nix, course-management, ... }:
let
  hostName = "phil.${config.networking.domain}";
in
{
  services.nginx.virtualHosts."${hostName}" = {
    locations."/".proxyPass = "http://127.0.0.1:8084";
    enableACME = true;
    forceSSL = true;
  };

  containers."courses-phil" = {
    autoStart = true;
    # forbidden sadly, I will copy the keys manually. Not very beautiful but it works
    # bindMounts = {
    #   hostPath = "/etc/ssh";
    #   mountPoint = "/etc/ssh";
    # };
    config = { pkgs, config, ... }: {
      networking.domain = "ifsr.de";
      imports = [
        sops-nix.nixosModules.sops
        course-management.nixosModules.default
      ];
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      sops.age.generateKey = false;
      sops.defaultSopsFile = ../secrets/quitte.yaml;
      sops.secrets =
        let inherit (config.services.course-management) user;
        in
        {
          "course-management-phil/secret-key".owner = user;
          "course-management-phil/adminpass".owner = user;
        };
      systemd.services.course-management.after = [ "postgresql.service" ];
      services.course-management = {
        inherit hostName;
        enable = true;
        listenPort = 5001;

        settings = {
          secretKeyFile = config.sops.secrets."course-management-phil/secret-key".path;
          adminPassFile = config.sops.secrets."course-management-phil/adminpass".path;
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
        # port = 55555;
        ensureUsers = [{
          name = "course-management";
          ensurePermissions = {
            "DATABASE \"course-management\"" = "ALL PRIVILEGES";
          };
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
