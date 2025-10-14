{ config, pkgs, ... }:
let
  domain = "nc.${config.networking.domain}";
in
{
  sops.secrets = {
    nextcloud_adminpass.owner = "nextcloud";
  };

  services = {
    nextcloud = {
      enable = true;
      configureRedis = true;
      package = pkgs.nextcloud31;
      hostName = domain;
      https = true; # Use https for all urls
      config = {
        dbtype = "pgsql";
        adminpassFile = config.sops.secrets.nextcloud_adminpass.path;
        adminuser = "root";
      };
      # postgres database is configured automatically
      database.createLocally = true;

      # enable HEIC image preview
      settings.enabledPreviewProviders = [
        "OC\\Preview\\BMP"
        "OC\\Preview\\GIF"
        "OC\\Preview\\JPEG"
        "OC\\Preview\\Krita"
        "OC\\Preview\\MarkDown"
        "OC\\Preview\\MP3"
        "OC\\Preview\\OpenDocument"
        "OC\\Preview\\PNG"
        "OC\\Preview\\TXT"
        "OC\\Preview\\XBitmap"
        "OC\\Preview\\HEIC"
      ];

    };
  };

  # ensure that postgres is running *before* running the setup
  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
}
