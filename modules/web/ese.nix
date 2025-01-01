{ config, pkgs, ... }:
let
  domain = "ese.${config.networking.domain}";
  webRoot = "/srv/web/ese";
in
{
  services.nginx = {
    virtualHosts."${domain}" = {
      locations."= /" = {
        return = "302 /2025/";
      };
      locations."/" = {
        root = webRoot;
        tryFiles = "$uri $uri/ =404";
      };
      # cache static assets
      locations."~* \.(?:css|svg|webp|jpg|jpeg|gif|png|ico|mp4|mp3|ogg|ogv|webm|ttf|woff2|woff)$" = {
        root = webRoot;
        extraConfig = ''
          expires 1y;
        '';
      };
    };
  };

  users.users."ese-deploy" = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      ''command="${pkgs.rrsync}/bin/rrsync ${webRoot}",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWGdTdobZN2oSLsTQmHOahdc9vqyuwUBS0PSk5IQhGV''
    ];
  };

}
