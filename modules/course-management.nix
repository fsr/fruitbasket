{ config, lib, pkgs, ... }:
let
  hostName = "kurse.${config.fsr.domain}";
in
{
  sops.secrets =
    let inherit (config.services.course-management) user;
    in
    {
      "course-management/secret-key".owner = user;
      "course-management/adminpass".owner = user;
    };

  services.course-management = {
    inherit hostName;
    enable = true;

    settings = {
      secretKeyFile = config.sops.secrets."course-management/secret-key".path;
      adminPassFile = config.sops.secrets."course-management/adminpass".path;
      admins = [{
        name = "Root iFSR";
        email = "root@${config.fsr.domain}";
      }];
      database = {
        ENGINE = "django.db.backends.postgresql";
        NAME = "course-management";
      };
      email = lib.mkDefault {
        fromEmail = "noreply@${config.fsr.domain}";
        serverEmail = "root@${config.fsr.domain}";
      };
    };
  };

  services.postgresql = {
    enable = lib.mkForce true; # upstream bacula config wants to disable it, so we need to force
    ensureUsers = [{
      name = "course-management";
      ensurePermissions = {
        "DATABASE \"course-management\"" = "ALL PRIVILEGES";
      };
    }];
    ensureDatabases = [ "course-management" ];
  };

  services.nginx.virtualHosts.${hostName} = {
    enableACME = true;
    forceSSL = true;
  };
}
