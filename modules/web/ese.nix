{ config, ... }:
let
  domain = "ese.${config.networking.domain}";
in
{
  services.nginx = {
    virtualHosts."${domain}" = {
      locations."= /" = {
        # temporary redirect, to avoid caching problems
        return = "302 /2024/";
      };
      locations."/" = {
        root = "/srv/web/ese/served";
        tryFiles = "$uri $uri/ =404";
      };
      # cache static assets
      locations."~* \.(?:css|svg|webp|jpg|jpeg|gif|png|ico|mp4|mp3|ogg|ogv|webm|ttf|woff2|woff)$" = {
        root = "/srv/web/ese/served";
        extraConfig = ''
          expires 1y;
        '';
      };
    };
  };
}
