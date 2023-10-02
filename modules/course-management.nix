{ config, lib, ... }:
let
  hostName = "kurse.${config.networking.domain}";
in
{
  sops.secrets =
    let inherit (config.services.course-management) user;
    in
    {
      "course-management/secret-key".owner = user;
      "course-management/adminpass".owner = user;
    };

  systemd.services.course-management.after = [ "postgresql.service" ];
  services.course-management = {
    inherit hostName;
    enable = true;

    settings = {
      secretKeyFile = config.sops.secrets."course-management/secret-key".path;
      adminPassFile = config.sops.secrets."course-management/adminpass".path;
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

    # phil redirects
    locations =
      let
        philDomain = "https://kurse-phil.ifsr.de";
        courses = [ "238" "239" "240" "241" "242" "243" ];
        subjects = [
          "ESE 2023 PHIL Campustour"
          "ESE 2023 PHIL Bowlingabend"
          "ESE 2023 PHIL Filmabend"
          "ESE 2023 PHIL Wandern"
          "ESE 2023 PHIL Spieleabend Pen and Paper"
        ];
      in
      {
        "~ \"^/course/(${builtins.concatStringsSep "|" courses})/\"".return = "301 ${philDomain}/course/$1";
        "~ \"^/subject/(${builtins.concatStringsSep "|" subjects})/\"".return = "301 ${philDomain}/subject/$1";
      };
  };
}
