{ config, lib, pkgs, ... }:
let
  domain = "tickets.${config.networking.domain}";
in
{
  services.zammad = {
    enable = true;
    database = {
      createLocally = true;
      type = "PostgreSQL";
    };
    port = 8085;
    secretKeyBaseFile = config.sops.secrets."zammad_secret".path;
  };


  # disably spammy logs
  systemd.services.zammad-web.preStart = ''
    sed -i -e "s|debug|warn|" ./config/environments/production.rb 
  '';

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.zammad.port}";
    };
    locations."/ws" = {
      proxyPass = "http://localhost:${toString config.services.zammad.websocketPort}";
      proxyWebsockets = true;
    };
  };

  sops.secrets."zammad_secret".owner = "zammad";
}
